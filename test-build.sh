#!/bin/bash

# Monika 构建测试脚本
# 快速测试构建是否正常

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🧪 Monika 构建测试脚本"
echo "====================="

BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# 测试前端构建
log_info "测试前端 Docker 构建..."
if docker build \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    --build-arg GIT_COMMIT="$GIT_COMMIT" \
    --tag "monika-frontend:test" \
    ./frontend > /dev/null 2>&1; then
    log_success "前端构建成功"
    docker rmi monika-frontend:test > /dev/null 2>&1
else
    log_error "前端构建失败"
    echo ""
    echo "详细错误信息："
    docker build \
        --build-arg BUILD_DATE="$BUILD_DATE" \
        --build-arg GIT_COMMIT="$GIT_COMMIT" \
        --tag "monika-frontend:test" \
        ./frontend
    exit 1
fi

# 测试后端构建
log_info "测试后端 Docker 构建..."
if docker build \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    --build-arg GIT_COMMIT="$GIT_COMMIT" \
    --tag "monika-backend:test" \
    ./backend > /dev/null 2>&1; then
    log_success "后端构建成功"
    docker rmi monika-backend:test > /dev/null 2>&1
else
    log_error "后端构建失败"
    echo ""
    echo "详细错误信息："
    docker build \
        --build-arg BUILD_DATE="$BUILD_DATE" \
        --build-arg GIT_COMMIT="$GIT_COMMIT" \
        --tag "monika-backend:test" \
        ./backend
    exit 1
fi

log_success "🎉 所有构建测试通过！"
echo ""
echo "现在可以安全地运行完整部署："
echo "  ./deploy/build-and-push.sh"
