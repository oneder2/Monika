#!/bin/bash

# Monika 部署状态检查脚本
# 使用方法: ./check-deployment.sh [server]

set -e

# 配置变量
PRODUCTION_SERVER="${1:-${PRODUCTION_SERVER}}"
DEPLOY_USER="${DEPLOY_USER:-deploy}"
DEPLOY_PATH="${DEPLOY_PATH:-/opt/monika}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查参数
check_parameters() {
    if [ -z "$PRODUCTION_SERVER" ]; then
        log_error "生产服务器地址未指定"
        echo "使用方法: $0 [server]"
        echo "或设置环境变量: PRODUCTION_SERVER=your-server.com"
        exit 1
    fi
    
    log_info "检查服务器: $PRODUCTION_SERVER"
}

# 检查服务器连接
check_server_connection() {
    log_info "检查服务器连接..."
    
    if ssh -o ConnectTimeout=10 -o BatchMode=yes "$DEPLOY_USER@$PRODUCTION_SERVER" "echo 'Connected'" &>/dev/null; then
        log_success "服务器连接正常"
    else
        log_error "无法连接到服务器 $PRODUCTION_SERVER"
        return 1
    fi
}

# 检查容器状态
check_container_status() {
    log_info "检查容器状态..."
    
    container_status=$(ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "
        cd $DEPLOY_PATH 2>/dev/null || exit 1
        if [ -f docker-compose.prod.yml ]; then
            docker compose -f docker-compose.prod.yml ps --format json 2>/dev/null || echo '[]'
        else
            echo '[]'
        fi
    ")
    
    if [ "$container_status" = "[]" ] || [ -z "$container_status" ]; then
        log_warning "未找到运行中的容器"
        return 1
    fi
    
    # 解析容器状态
    backend_status=$(echo "$container_status" | grep -o '"State":"[^"]*"' | grep backend | cut -d'"' -f4)
    frontend_status=$(echo "$container_status" | grep -o '"State":"[^"]*"' | grep frontend | cut -d'"' -f4)
    
    if [ "$backend_status" = "running" ]; then
        log_success "后端容器运行正常"
    else
        log_error "后端容器状态异常: $backend_status"
    fi
    
    if [ "$frontend_status" = "running" ]; then
        log_success "前端容器运行正常"
    else
        log_error "前端容器状态异常: $frontend_status"
    fi
}

# 检查服务健康状态
check_service_health() {
    log_info "检查服务健康状态..."
    
    # 检查后端健康状态
    backend_health=$(ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/health" 2>/dev/null)
    
    if [ "$backend_health" = "200" ]; then
        log_success "后端服务健康检查通过"
    else
        log_error "后端服务健康检查失败 (HTTP $backend_health)"
    fi
    
    # 检查前端服务
    frontend_health=$(ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "curl -s -o /dev/null -w '%{http_code}' http://localhost/" 2>/dev/null)
    
    if [ "$frontend_health" = "200" ]; then
        log_success "前端服务健康检查通过"
    else
        log_error "前端服务健康检查失败 (HTTP $frontend_health)"
    fi
}

# 检查资源使用情况
check_resource_usage() {
    log_info "检查资源使用情况..."
    
    ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "
        echo '=== 系统资源使用情况 ==='
        echo '磁盘使用:'
        df -h | grep -E '(Filesystem|/dev/)'
        echo ''
        echo '内存使用:'
        free -h
        echo ''
        echo '=== Docker 资源使用情况 ==='
        if command -v docker &> /dev/null; then
            echo 'Docker 磁盘使用:'
            docker system df 2>/dev/null || echo 'Docker 系统信息获取失败'
            echo ''
            echo '容器资源使用:'
            docker stats --no-stream --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}' 2>/dev/null || echo 'Docker 统计信息获取失败'
        else
            echo 'Docker 未安装'
        fi
    "
}

# 检查日志
check_logs() {
    log_info "检查最近的服务日志..."
    
    ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "
        cd $DEPLOY_PATH 2>/dev/null || exit 1
        if [ -f docker-compose.prod.yml ]; then
            echo '=== 最近的服务日志 (最后20行) ==='
            docker compose -f docker-compose.prod.yml logs --tail=20 2>/dev/null || echo '日志获取失败'
        else
            echo '未找到 docker-compose.prod.yml 文件'
        fi
    "
}

# 检查备份状态
check_backup_status() {
    log_info "检查备份状态..."
    
    ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "
        cd $DEPLOY_PATH 2>/dev/null || exit 1
        echo '=== 备份文件状态 ==='
        if [ -d backups ]; then
            echo '最近的备份文件:'
            ls -lt backups/ | head -5
            echo ''
            echo '备份目录大小:'
            du -sh backups/ 2>/dev/null || echo '备份目录大小获取失败'
        else
            echo '未找到备份目录'
        fi
    "
}

# 检查网络连通性
check_network_connectivity() {
    log_info "检查网络连通性..."
    
    # 检查外部访问
    if curl -s -o /dev/null -w '%{http_code}' "http://$PRODUCTION_SERVER" | grep -q "200\|301\|302"; then
        log_success "外部网络访问正常"
    else
        log_warning "外部网络访问可能存在问题"
    fi
    
    # 检查内部网络
    ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "
        echo '=== 网络端口监听状态 ==='
        netstat -tlnp 2>/dev/null | grep -E ':(80|443|8000)' || echo '端口监听信息获取失败'
    "
}

# 生成状态报告
generate_status_report() {
    log_info "生成状态报告..."
    
    report_file="deployment-status-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "Monika 部署状态报告"
        echo "==================="
        echo "检查时间: $(date)"
        echo "目标服务器: $PRODUCTION_SERVER"
        echo "部署路径: $DEPLOY_PATH"
        echo ""
        
        echo "=== 容器状态 ==="
        ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "
            cd $DEPLOY_PATH 2>/dev/null && docker compose -f docker-compose.prod.yml ps 2>/dev/null || echo '容器状态获取失败'
        "
        echo ""
        
        echo "=== 服务健康状态 ==="
        echo "后端健康检查: $(ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/health" 2>/dev/null)"
        echo "前端健康检查: $(ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "curl -s -o /dev/null -w '%{http_code}' http://localhost/" 2>/dev/null)"
        echo ""
        
        echo "=== 系统资源 ==="
        ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "
            echo '磁盘使用:'
            df -h | grep -E '(Filesystem|/dev/)'
            echo ''
            echo '内存使用:'
            free -h
        "
        
    } > "$report_file"
    
    log_success "状态报告已保存到: $report_file"
}

# 显示帮助信息
show_help() {
    echo "Monika 部署状态检查脚本"
    echo ""
    echo "使用方法:"
    echo "  $0 [server]"
    echo ""
    echo "参数:"
    echo "  server  - 生产服务器地址 (可通过环境变量 PRODUCTION_SERVER 设置)"
    echo ""
    echo "环境变量:"
    echo "  PRODUCTION_SERVER  - 生产服务器地址"
    echo "  DEPLOY_USER        - 部署用户名 (默认: deploy)"
    echo "  DEPLOY_PATH        - 部署路径 (默认: /opt/monika)"
    echo ""
    echo "示例:"
    echo "  $0 production.example.com"
    echo "  PRODUCTION_SERVER=prod.example.com $0"
}

# 主函数
main() {
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_help
        exit 0
    fi
    
    echo "🔍 Monika 部署状态检查"
    echo "====================="
    echo ""
    
    check_parameters
    
    # 执行检查
    if check_server_connection; then
        check_container_status
        check_service_health
        check_resource_usage
        check_logs
        check_backup_status
        check_network_connectivity
        generate_status_report
        
        echo ""
        log_success "✅ 部署状态检查完成"
        echo ""
        echo "快速访问链接:"
        echo "  前端应用: http://$PRODUCTION_SERVER"
        echo "  后端 API: http://$PRODUCTION_SERVER:8000"
        echo "  API 文档: http://$PRODUCTION_SERVER:8000/docs"
    else
        log_error "❌ 服务器连接失败，无法执行检查"
        exit 1
    fi
}

# 运行主函数
main "$@"
