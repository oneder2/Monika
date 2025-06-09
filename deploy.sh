#!/bin/bash

# Monika 部署脚本
# 用法: ./deploy.sh [dev|prod|backup]

set -e

# 颜色定义
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

# 检查Docker是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi

    # 检查 docker compose 或 docker-compose
    if ! docker compose version &> /dev/null && ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi

    # 设置compose命令
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_CMD="docker-compose"
    fi
}

# 创建必要的目录
create_directories() {
    log_info "创建必要的目录..."
    mkdir -p data
    mkdir -p backups
    mkdir -p logs
}

# 检查环境变量文件
check_env_file() {
    if [ ! -f .env ]; then
        log_warning ".env 文件不存在，从示例文件创建..."
        cp .env.example .env
        log_warning "请编辑 .env 文件并设置适当的配置值"
    fi
}

# 开发环境部署
deploy_dev() {
    log_info "部署开发环境..."
    check_env_file
    create_directories

    log_info "停止现有容器..."
    $COMPOSE_CMD down --remove-orphans

    log_info "构建并启动服务..."
    $COMPOSE_CMD up --build -d

    log_success "开发环境部署完成！"
    log_info "前端访问地址: http://localhost"
    log_info "后端API文档: http://localhost:8000/docs"
}

# 生产环境部署
deploy_prod() {
    log_info "部署生产环境..."
    check_env_file
    create_directories

    # 检查关键环境变量
    if grep -q "your-super-secret-key" .env; then
        log_error "请在 .env 文件中设置安全的 SECRET_KEY"
        exit 1
    fi

    log_info "停止现有容器..."
    $COMPOSE_CMD -f docker-compose.prod.yml down --remove-orphans

    log_info "构建并启动生产服务..."
    $COMPOSE_CMD -f docker-compose.prod.yml up --build -d

    log_success "生产环境部署完成！"
    log_info "应用访问地址: http://localhost"
}

# 备份数据库
backup_database() {
    log_info "执行数据库备份..."
    $COMPOSE_CMD -f docker-compose.prod.yml --profile backup run --rm db-backup
    log_success "数据库备份完成！"
}

# 查看日志
show_logs() {
    log_info "显示应用日志..."
    $COMPOSE_CMD logs -f
}

# 停止服务
stop_services() {
    log_info "停止所有服务..."
    $COMPOSE_CMD down
    $COMPOSE_CMD -f docker-compose.prod.yml down
    log_success "服务已停止"
}

# 清理资源
cleanup() {
    log_info "清理Docker资源..."
    docker system prune -f
    log_success "清理完成"
}

# 主函数
main() {
    check_docker
    
    case "${1:-dev}" in
        "dev")
            deploy_dev
            ;;
        "prod")
            deploy_prod
            ;;
        "backup")
            backup_database
            ;;
        "logs")
            show_logs
            ;;
        "stop")
            stop_services
            ;;
        "cleanup")
            cleanup
            ;;
        *)
            echo "用法: $0 [dev|prod|backup|logs|stop|cleanup]"
            echo ""
            echo "命令说明:"
            echo "  dev     - 部署开发环境 (默认)"
            echo "  prod    - 部署生产环境"
            echo "  backup  - 备份数据库"
            echo "  logs    - 查看应用日志"
            echo "  stop    - 停止所有服务"
            echo "  cleanup - 清理Docker资源"
            exit 1
            ;;
    esac
}

main "$@"
