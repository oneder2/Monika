#!/bin/bash

# Monika 项目一键部署脚本
# 集成构建、推送和部署的完整流程
# 使用方法: ./deploy.sh [tag] [server]

set -e  # 遇到错误立即退出

# 配置变量
IMAGE_TAG="${1:-latest}"
PRODUCTION_SERVER="${2:-${PRODUCTION_SERVER}}"

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

# 显示帮助信息
show_help() {
    echo "Monika 项目一键部署脚本"
    echo ""
    echo "使用方法:"
    echo "  $0 [tag] [server]"
    echo ""
    echo "参数:"
    echo "  tag     - Docker 镜像标签 (默认: latest)"
    echo "  server  - 生产服务器地址 (可通过环境变量 PRODUCTION_SERVER 设置)"
    echo ""
    echo "环境变量:"
    echo "  PRODUCTION_SERVER  - 生产服务器地址"
    echo "  DOCKER_REGISTRY    - Docker 镜像仓库地址"
    echo "  DEPLOY_USER        - 部署用户名"
    echo "  DEPLOY_PATH        - 部署路径"
    echo ""
    echo "示例:"
    echo "  $0 v1.0.0 production.example.com"
    echo "  PRODUCTION_SERVER=prod.example.com $0 latest"
    echo ""
    echo "部署流程:"
    echo "  1. 检查环境和参数"
    echo "  2. 构建 Docker 镜像"
    echo "  3. 推送镜像到仓库"
    echo "  4. 连接生产服务器"
    echo "  5. 备份当前部署"
    echo "  6. 部署新版本"
    echo "  7. 执行健康检查"
    echo "  8. 清理旧镜像"
}

# 检查参数
check_parameters() {
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_help
        exit 0
    fi
    
    if [ -z "$PRODUCTION_SERVER" ]; then
        log_error "生产服务器地址未指定"
        echo ""
        show_help
        exit 1
    fi
    
    log_info "部署配置:"
    echo "  镜像标签: $IMAGE_TAG"
    echo "  目标服务器: $PRODUCTION_SERVER"
    echo "  Docker 仓库: ${DOCKER_REGISTRY:-docker.io/your-username}"
    echo ""
}

# 检查必要文件
check_required_files() {
    log_info "检查必要文件..."
    
    required_files=(
        "deploy/build-and-push.sh"
        "deploy/deploy-to-production.sh"
        "deploy/docker-compose.prod.yml"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "缺少必要文件: $file"
            exit 1
        fi
    done
    
    # 确保脚本可执行
    chmod +x deploy/build-and-push.sh
    chmod +x deploy/deploy-to-production.sh
    
    log_success "必要文件检查通过"
}

# 确认部署
confirm_deployment() {
    echo ""
    log_warning "即将执行完整的生产环境部署流程"
    echo "这将会:"
    echo "  1. 构建新的 Docker 镜像"
    echo "  2. 推送镜像到仓库"
    echo "  3. 在生产服务器上部署新版本"
    echo "  4. 可能会导致短暂的服务中断"
    echo ""
    
    read -p "确认继续部署? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "部署已取消"
        exit 0
    fi
}

# 执行构建和推送
execute_build_and_push() {
    log_info "🔨 开始构建和推送阶段..."
    echo "================================"
    
    if ./deploy/build-and-push.sh "$IMAGE_TAG"; then
        log_success "构建和推送完成"
    else
        log_error "构建和推送失败"
        exit 1
    fi
}

# 执行生产部署
execute_production_deployment() {
    log_info "🚀 开始生产部署阶段..."
    echo "=========================="
    
    if ./deploy/deploy-to-production.sh "$IMAGE_TAG" "$PRODUCTION_SERVER"; then
        log_success "生产部署完成"
    else
        log_error "生产部署失败"
        exit 1
    fi
}

# 显示部署结果
show_deployment_result() {
    echo ""
    echo "🎉 Monika 项目部署完成!"
    echo "======================="
    echo ""
    echo "部署信息:"
    echo "  镜像版本: $IMAGE_TAG"
    echo "  部署时间: $(date)"
    echo "  目标服务器: $PRODUCTION_SERVER"
    echo ""
    echo "服务访问地址:"
    echo "  前端应用: http://$PRODUCTION_SERVER"
    echo "  后端 API: http://$PRODUCTION_SERVER:8000"
    echo "  API 文档: http://$PRODUCTION_SERVER:8000/docs"
    echo ""
    echo "管理命令:"
    echo "  查看日志: ssh $DEPLOY_USER@$PRODUCTION_SERVER 'cd $DEPLOY_PATH && docker compose -f docker-compose.prod.yml logs -f'"
    echo "  重启服务: ssh $DEPLOY_USER@$PRODUCTION_SERVER 'cd $DEPLOY_PATH && docker compose -f docker-compose.prod.yml restart'"
    echo "  停止服务: ssh $DEPLOY_USER@$PRODUCTION_SERVER 'cd $DEPLOY_PATH && docker compose -f docker-compose.prod.yml down'"
    echo ""
    echo "备份命令:"
    echo "  手动备份: ssh $DEPLOY_USER@$PRODUCTION_SERVER 'cd $DEPLOY_PATH && docker compose -f docker-compose.prod.yml --profile backup run --rm db-backup'"
    echo ""
}

# 主函数
main() {
    echo "🚀 Monika 项目一键部署脚本"
    echo "=========================="
    echo ""
    
    check_parameters "$@"
    check_required_files
    confirm_deployment
    
    # 记录开始时间
    start_time=$(date +%s)
    
    # 执行部署流程
    execute_build_and_push
    execute_production_deployment
    
    # 计算部署时间
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    show_deployment_result
    
    log_success "总部署时间: ${duration}秒"
}

# 运行主函数
main "$@"
