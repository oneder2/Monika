#!/bin/bash

# Monika 项目构建和推送脚本
# 使用方法: ./build-and-push.sh [tag]

set -e  # 遇到错误立即退出

# 配置变量
PROJECT_NAME="monika"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-docker.io/your-username}"  # 默认使用 Docker Hub
IMAGE_TAG="${1:-latest}"  # 使用传入的标签或默认为 latest
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
GIT_COMMIT=$(git rev-parse --short HEAD)

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

# 检查必要工具
check_requirements() {
    log_info "检查构建环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装或不在 PATH 中"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        log_error "Git 未安装或不在 PATH 中"
        exit 1
    fi
    
    # 检查 Docker 是否运行
    if ! docker info &> /dev/null; then
        log_error "Docker 服务未运行"
        exit 1
    fi
    
    log_success "构建环境检查通过"
}

# 检查 Git 状态
check_git_status() {
    log_info "检查 Git 状态..."
    
    # 检查是否在 main 分支
    current_branch=$(git branch --show-current)
    if [ "$current_branch" != "main" ]; then
        log_warning "当前不在 main 分支 (当前: $current_branch)"
        read -p "是否继续? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "构建已取消"
            exit 0
        fi
    fi
    
    # 检查是否有未提交的更改
    if ! git diff-index --quiet HEAD --; then
        log_warning "存在未提交的更改"
        read -p "是否继续? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "构建已取消"
            exit 0
        fi
    fi
    
    log_success "Git 状态检查完成"
}

# 构建镜像
build_images() {
    log_info "开始构建 Docker 镜像..."
    
    # 构建后端镜像
    log_info "构建后端镜像..."
    docker build \
        --build-arg BUILD_DATE="$BUILD_DATE" \
        --build-arg GIT_COMMIT="$GIT_COMMIT" \
        --tag "${DOCKER_REGISTRY}/${PROJECT_NAME}-backend:${IMAGE_TAG}" \
        --tag "${DOCKER_REGISTRY}/${PROJECT_NAME}-backend:latest" \
        ./backend
    
    if [ $? -eq 0 ]; then
        log_success "后端镜像构建成功"
    else
        log_error "后端镜像构建失败"
        exit 1
    fi
    
    # 构建前端镜像
    log_info "构建前端镜像..."
    docker build \
        --build-arg BUILD_DATE="$BUILD_DATE" \
        --build-arg GIT_COMMIT="$GIT_COMMIT" \
        --tag "${DOCKER_REGISTRY}/${PROJECT_NAME}-frontend:${IMAGE_TAG}" \
        --tag "${DOCKER_REGISTRY}/${PROJECT_NAME}-frontend:latest" \
        ./frontend
    
    if [ $? -eq 0 ]; then
        log_success "前端镜像构建成功"
    else
        log_error "前端镜像构建失败"
        exit 1
    fi
    
    log_success "所有镜像构建完成"
}

# 推送镜像
push_images() {
    log_info "开始推送镜像到仓库..."
    
    # 登录 Docker 仓库（如果需要）
    if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
        log_info "登录 Docker 仓库..."
        echo "$DOCKER_PASSWORD" | docker login "$DOCKER_REGISTRY" -u "$DOCKER_USERNAME" --password-stdin
    fi
    
    # 推送后端镜像
    log_info "推送后端镜像..."
    docker push "${DOCKER_REGISTRY}/${PROJECT_NAME}-backend:${IMAGE_TAG}"
    docker push "${DOCKER_REGISTRY}/${PROJECT_NAME}-backend:latest"
    
    # 推送前端镜像
    log_info "推送前端镜像..."
    docker push "${DOCKER_REGISTRY}/${PROJECT_NAME}-frontend:${IMAGE_TAG}"
    docker push "${DOCKER_REGISTRY}/${PROJECT_NAME}-frontend:latest"
    
    log_success "镜像推送完成"
}

# 清理本地镜像（可选）
cleanup_local_images() {
    read -p "是否清理本地构建的镜像? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "清理本地镜像..."
        docker rmi "${DOCKER_REGISTRY}/${PROJECT_NAME}-backend:${IMAGE_TAG}" || true
        docker rmi "${DOCKER_REGISTRY}/${PROJECT_NAME}-frontend:${IMAGE_TAG}" || true
        log_success "本地镜像清理完成"
    fi
}

# 显示构建信息
show_build_info() {
    log_info "构建信息:"
    echo "  项目名称: $PROJECT_NAME"
    echo "  镜像标签: $IMAGE_TAG"
    echo "  仓库地址: $DOCKER_REGISTRY"
    echo "  构建时间: $BUILD_DATE"
    echo "  Git 提交: $GIT_COMMIT"
    echo "  当前分支: $(git branch --show-current)"
    echo ""
    echo "将构建的镜像:"
    echo "  - ${DOCKER_REGISTRY}/${PROJECT_NAME}-backend:${IMAGE_TAG}"
    echo "  - ${DOCKER_REGISTRY}/${PROJECT_NAME}-frontend:${IMAGE_TAG}"
    echo ""
}

# 主函数
main() {
    echo "🚀 Monika 项目构建和推送脚本"
    echo "=================================="
    
    show_build_info
    
    # 确认构建
    read -p "是否继续构建和推送? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "构建已取消"
        exit 0
    fi
    
    check_requirements
    check_git_status
    build_images
    push_images
    cleanup_local_images
    
    log_success "🎉 构建和推送完成!"
    echo ""
    echo "下一步: 使用以下命令部署到生产环境:"
    echo "  ./deploy-to-production.sh $IMAGE_TAG"
}

# 运行主函数
main "$@"
