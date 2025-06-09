#!/bin/bash

# Monika 构建问题修复脚本
# 解决前端构建中的依赖和参数问题

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🔧 Monika 构建问题修复脚本"
echo "========================="

# 1. 清理 Docker 缓存
log_info "清理 Docker 构建缓存..."
docker builder prune -f
docker system prune -f

# 2. 检查前端依赖
log_info "检查前端依赖..."
cd frontend
if [ ! -d "node_modules" ]; then
    log_info "安装前端依赖..."
    npm install
else
    log_info "更新前端依赖..."
    npm ci
fi

# 3. 测试本地构建
log_info "测试本地前端构建..."
npm run build
if [ $? -eq 0 ]; then
    log_success "本地前端构建成功"
else
    log_error "本地前端构建失败"
    exit 1
fi

cd ..

# 4. 重新构建 Docker 镜像
log_info "重新构建前端 Docker 镜像..."
docker build \
    --no-cache \
    --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    --build-arg GIT_COMMIT="$(git rev-parse --short HEAD)" \
    --tag "monika-frontend:test" \
    ./frontend

if [ $? -eq 0 ]; then
    log_success "前端 Docker 镜像构建成功"
else
    log_error "前端 Docker 镜像构建失败"
    exit 1
fi

# 5. 测试镜像
log_info "测试前端镜像..."
docker run --rm -d --name monika-frontend-test -p 8081:80 monika-frontend:test
sleep 5

if curl -f http://localhost:8081 > /dev/null 2>&1; then
    log_success "前端镜像测试成功"
else
    log_warning "前端镜像测试失败，但镜像构建成功"
fi

# 清理测试容器
docker stop monika-frontend-test > /dev/null 2>&1 || true
docker rmi monika-frontend:test > /dev/null 2>&1 || true

log_success "🎉 构建问题修复完成！"
echo ""
echo "现在可以重新运行部署脚本："
echo "  ./deploy/build-and-push.sh"
echo "  或"
echo "  ./deploy/deploy.sh"
