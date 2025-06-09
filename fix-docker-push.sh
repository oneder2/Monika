#!/bin/bash

# Docker 推送问题修复脚本

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

echo "🔧 Docker 推送问题修复脚本"
echo "========================="

# 检查 Docker 登录状态
check_docker_login() {
    log_info "检查 Docker 登录状态..."
    
    if docker info | grep -q "Username:"; then
        username=$(docker info | grep "Username:" | awk '{print $2}')
        log_success "已登录 Docker Hub，用户名: $username"
        return 0
    else
        log_warning "未登录 Docker Hub"
        return 1
    fi
}

# 提供解决方案选项
show_solutions() {
    echo ""
    log_info "请选择解决方案:"
    echo "1. 使用本地镜像仓库（不推送到远程）"
    echo "2. 配置 Docker Hub 账户并推送"
    echo "3. 使用 GitHub Container Registry"
    echo "4. 跳过推送，仅本地构建"
    echo ""
    read -p "请选择 (1-4): " choice
    
    case $choice in
        1) setup_local_registry ;;
        2) setup_docker_hub ;;
        3) setup_github_registry ;;
        4) skip_push ;;
        *) log_error "无效选择"; exit 1 ;;
    esac
}

# 方案 1: 本地镜像仓库
setup_local_registry() {
    log_info "设置本地镜像仓库..."
    
    # 修改配置使用本地标签
    cat > deploy/.env.production << EOF
# Monika 生产环境配置文件 - 本地部署版本

# Docker 镜像配置（本地）
DOCKER_REGISTRY=localhost
IMAGE_TAG=latest

# 应用安全配置
SECRET_KEY=$(openssl rand -hex 32)
ACCESS_TOKEN_EXPIRE_MINUTES=1440

# 数据库配置
DATABASE_URL=sqlite:///./data/monika.db

# 服务器配置（本地）
PRODUCTION_SERVER=localhost
DEPLOY_USER=\$USER
DEPLOY_PATH=\$PWD/deploy-local

# 备份配置
BACKUP_RETENTION_DAYS=7

# 监控配置
ENABLE_LOGGING=true
LOG_LEVEL=INFO
EOF
    
    # 创建本地部署脚本
    cat > deploy-local.sh << 'EOF'
#!/bin/bash

# 本地部署脚本（不推送到远程仓库）

echo "🏠 Monika 本地部署"
echo "=================="

# 构建镜像
echo "构建镜像..."
docker build --tag monika-backend:latest ./backend
docker build --tag monika-frontend:latest ./frontend

# 更新 docker-compose 配置
sed 's|${DOCKER_REGISTRY}/monika-|monika-|g' deploy/docker-compose.prod.yml > docker-compose.local.yml

# 启动服务
echo "启动服务..."
docker compose -f docker-compose.local.yml down || true
docker compose -f docker-compose.local.yml up -d

echo ""
echo "✅ 本地部署完成！"
echo "访问地址:"
echo "  前端: http://localhost:8080"
echo "  后端: http://localhost:8000"
echo "  API文档: http://localhost:8000/docs"
EOF
    
    chmod +x deploy-local.sh
    
    log_success "本地部署配置完成！"
    echo ""
    echo "使用方法:"
    echo "  ./deploy-local.sh"
}

# 方案 2: Docker Hub
setup_docker_hub() {
    log_info "配置 Docker Hub..."
    
    read -p "请输入您的 Docker Hub 用户名: " docker_username
    
    if [ -z "$docker_username" ]; then
        log_error "用户名不能为空"
        exit 1
    fi
    
    # 登录 Docker Hub
    log_info "登录 Docker Hub..."
    docker login
    
    if [ $? -eq 0 ]; then
        log_success "Docker Hub 登录成功"
        
        # 更新配置文件
        sed -i "s|docker.io/your-username|docker.io/$docker_username|g" deploy/.env.production
        
        log_success "配置已更新，现在可以重新运行部署脚本"
        echo "  ./deploy/build-and-push.sh"
    else
        log_error "Docker Hub 登录失败"
        exit 1
    fi
}

# 方案 3: GitHub Container Registry
setup_github_registry() {
    log_info "配置 GitHub Container Registry..."
    
    read -p "请输入您的 GitHub 用户名: " github_username
    
    if [ -z "$github_username" ]; then
        log_error "用户名不能为空"
        exit 1
    fi
    
    echo ""
    log_info "请创建 GitHub Personal Access Token:"
    echo "1. 访问: https://github.com/settings/tokens"
    echo "2. 创建新 token，选择 'write:packages' 权限"
    echo "3. 复制 token"
    echo ""
    
    read -p "请输入您的 GitHub Token: " github_token
    
    if [ -z "$github_token" ]; then
        log_error "Token 不能为空"
        exit 1
    fi
    
    # 登录 GitHub Container Registry
    echo "$github_token" | docker login ghcr.io -u "$github_username" --password-stdin
    
    if [ $? -eq 0 ]; then
        log_success "GitHub Container Registry 登录成功"
        
        # 更新配置文件
        sed -i "s|docker.io/your-username|ghcr.io/$github_username|g" deploy/.env.production
        
        log_success "配置已更新，现在可以重新运行部署脚本"
        echo "  ./deploy/build-and-push.sh"
    else
        log_error "GitHub Container Registry 登录失败"
        exit 1
    fi
}

# 方案 4: 跳过推送
skip_push() {
    log_info "创建仅构建脚本..."
    
    cat > build-only.sh << 'EOF'
#!/bin/bash

# 仅构建镜像，不推送

echo "🔨 Monika 镜像构建（仅本地）"
echo "=========================="

BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
GIT_COMMIT=$(git rev-parse --short HEAD)

# 构建后端镜像
echo "构建后端镜像..."
docker build \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    --build-arg GIT_COMMIT="$GIT_COMMIT" \
    --tag "monika-backend:latest" \
    ./backend

# 构建前端镜像
echo "构建前端镜像..."
docker build \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    --build-arg GIT_COMMIT="$GIT_COMMIT" \
    --tag "monika-frontend:latest" \
    ./frontend

echo ""
echo "✅ 镜像构建完成！"
echo "镜像列表:"
docker images | grep monika
EOF
    
    chmod +x build-only.sh
    
    log_success "仅构建脚本创建完成！"
    echo ""
    echo "使用方法:"
    echo "  ./build-only.sh"
}

# 主函数
main() {
    if ! check_docker_login; then
        show_solutions
    else
        log_info "Docker 已登录，问题可能是仓库地址配置错误"
        echo ""
        echo "当前配置的仓库地址: $(grep DOCKER_REGISTRY deploy/.env.production | cut -d'=' -f2)"
        echo ""
        show_solutions
    fi
}

# 运行主函数
main
