#!/bin/bash

# Monika 项目生产环境部署脚本
# 使用方法: ./deploy-to-production.sh [tag] [server]

set -e  # 遇到错误立即退出

# 配置变量
PROJECT_NAME="monika"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-docker.io/your-username}"
IMAGE_TAG="${1:-latest}"
PRODUCTION_SERVER="${2:-${PRODUCTION_SERVER}}"
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

# 检查必要参数
check_parameters() {
    if [ -z "$PRODUCTION_SERVER" ]; then
        log_error "生产服务器地址未指定"
        echo "使用方法: $0 [tag] [server]"
        echo "或设置环境变量: PRODUCTION_SERVER=your-server.com"
        exit 1
    fi
    
    log_info "部署参数:"
    echo "  目标服务器: $PRODUCTION_SERVER"
    echo "  部署用户: $DEPLOY_USER"
    echo "  部署路径: $DEPLOY_PATH"
    echo "  镜像标签: $IMAGE_TAG"
    echo "  镜像仓库: $DOCKER_REGISTRY"
}

# 检查服务器连接
check_server_connection() {
    log_info "检查服务器连接..."
    
    if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$DEPLOY_USER@$PRODUCTION_SERVER" "echo 'Connection test successful'" &>/dev/null; then
        log_error "无法连接到生产服务器 $PRODUCTION_SERVER"
        log_info "请确保:"
        echo "  1. 服务器地址正确"
        echo "  2. SSH 密钥已配置"
        echo "  3. 用户 $DEPLOY_USER 存在且有权限"
        exit 1
    fi
    
    log_success "服务器连接正常"
}

# 检查服务器环境
check_server_environment() {
    log_info "检查服务器环境..."
    
    # 检查 Docker 是否安装
    if ! ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "command -v docker &> /dev/null"; then
        log_error "生产服务器未安装 Docker"
        exit 1
    fi
    
    # 检查 Docker Compose 是否安装
    if ! ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "command -v docker-compose &> /dev/null || docker compose version &> /dev/null"; then
        log_error "生产服务器未安装 Docker Compose"
        exit 1
    fi
    
    # 检查部署目录
    ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "mkdir -p $DEPLOY_PATH"
    
    log_success "服务器环境检查通过"
}

# 备份当前部署
backup_current_deployment() {
    log_info "备份当前部署..."
    
    ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "
        cd $DEPLOY_PATH
        if [ -f docker-compose.prod.yml ]; then
            # 备份数据库
            if docker compose -f docker-compose.prod.yml ps | grep -q monika-backend-prod; then
                docker compose -f docker-compose.prod.yml --profile backup run --rm db-backup
                echo 'Database backup completed'
            fi
            
            # 备份配置文件
            backup_dir=\"backups/deployment-\$(date +%Y%m%d-%H%M%S)\"
            mkdir -p \"\$backup_dir\"
            cp -r . \"\$backup_dir/\" 2>/dev/null || true
            echo \"Configuration backup saved to \$backup_dir\"
        fi
    "
    
    log_success "备份完成"
}

# 上传部署文件
upload_deployment_files() {
    log_info "上传部署文件..."
    
    # 创建临时目录
    temp_dir=$(mktemp -d)
    
    # 复制部署文件到临时目录
    cp deploy/docker-compose.prod.yml "$temp_dir/"
    cp deploy/.env.production "$temp_dir/.env" 2>/dev/null || true
    
    # 创建环境变量文件
    cat > "$temp_dir/.env" << EOF
DOCKER_REGISTRY=$DOCKER_REGISTRY
IMAGE_TAG=$IMAGE_TAG
SECRET_KEY=${SECRET_KEY:-$(openssl rand -hex 32)}
ACCESS_TOKEN_EXPIRE_MINUTES=${ACCESS_TOKEN_EXPIRE_MINUTES:-1440}
EOF
    
    # 上传文件到服务器
    scp -r "$temp_dir"/* "$DEPLOY_USER@$PRODUCTION_SERVER:$DEPLOY_PATH/"
    
    # 清理临时目录
    rm -rf "$temp_dir"
    
    log_success "部署文件上传完成"
}

# 拉取最新镜像
pull_latest_images() {
    log_info "拉取最新镜像..."
    
    ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "
        cd $DEPLOY_PATH
        docker compose -f docker-compose.prod.yml pull
    "
    
    log_success "镜像拉取完成"
}

# 部署服务
deploy_services() {
    log_info "部署服务..."
    
    ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "
        cd $DEPLOY_PATH
        
        # 停止旧服务
        if [ -f docker-compose.prod.yml ]; then
            docker compose -f docker-compose.prod.yml down
        fi
        
        # 启动新服务
        docker compose -f docker-compose.prod.yml up -d
        
        # 等待服务启动
        echo 'Waiting for services to start...'
        sleep 30
        
        # 检查服务状态
        docker compose -f docker-compose.prod.yml ps
    "
    
    log_success "服务部署完成"
}

# 健康检查
health_check() {
    log_info "执行健康检查..."
    
    # 等待服务完全启动
    sleep 10
    
    # 检查后端健康状态
    if ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "curl -f http://localhost:8000/health" &>/dev/null; then
        log_success "后端服务健康检查通过"
    else
        log_error "后端服务健康检查失败"
        return 1
    fi
    
    # 检查前端服务
    if ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "curl -f http://localhost/" &>/dev/null; then
        log_success "前端服务健康检查通过"
    else
        log_error "前端服务健康检查失败"
        return 1
    fi
    
    log_success "所有服务健康检查通过"
}

# 回滚部署
rollback_deployment() {
    log_error "部署失败，开始回滚..."
    
    ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "
        cd $DEPLOY_PATH
        
        # 停止当前服务
        docker compose -f docker-compose.prod.yml down || true
        
        # 查找最新的备份
        latest_backup=\$(ls -1t backups/deployment-* 2>/dev/null | head -n1)
        
        if [ -n \"\$latest_backup\" ]; then
            echo \"Restoring from backup: \$latest_backup\"
            cp -r \"\$latest_backup\"/* . 2>/dev/null || true
            docker compose -f docker-compose.prod.yml up -d
            echo 'Rollback completed'
        else
            echo 'No backup found for rollback'
        fi
    "
    
    log_warning "回滚完成，请检查服务状态"
}

# 清理旧镜像
cleanup_old_images() {
    log_info "清理旧镜像..."
    
    ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "
        # 清理未使用的镜像
        docker image prune -f
        
        # 清理旧的项目镜像（保留最新的3个版本）
        docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.CreatedAt}}' | \
        grep '$DOCKER_REGISTRY/$PROJECT_NAME' | \
        tail -n +4 | \
        awk '{print \$1}' | \
        xargs -r docker rmi || true
    "
    
    log_success "镜像清理完成"
}

# 显示部署状态
show_deployment_status() {
    log_info "部署状态:"
    
    ssh "$DEPLOY_USER@$PRODUCTION_SERVER" "
        cd $DEPLOY_PATH
        echo '=== 容器状态 ==='
        docker compose -f docker-compose.prod.yml ps
        echo ''
        echo '=== 服务日志 (最近10行) ==='
        docker compose -f docker-compose.prod.yml logs --tail=10
    "
}

# 主函数
main() {
    echo "🚀 Monika 生产环境部署脚本"
    echo "============================="
    
    check_parameters
    
    # 确认部署
    echo ""
    read -p "是否继续部署到生产环境? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "部署已取消"
        exit 0
    fi
    
    # 执行部署流程
    check_server_connection
    check_server_environment
    backup_current_deployment
    upload_deployment_files
    pull_latest_images
    deploy_services
    
    # 健康检查
    if health_check; then
        cleanup_old_images
        show_deployment_status
        log_success "🎉 部署成功完成!"
        echo ""
        echo "服务访问地址:"
        echo "  前端: http://$PRODUCTION_SERVER"
        echo "  后端: http://$PRODUCTION_SERVER:8000"
        echo "  API文档: http://$PRODUCTION_SERVER:8000/docs"
    else
        rollback_deployment
        log_error "部署失败，已执行回滚"
        exit 1
    fi
}

# 运行主函数
main "$@"
