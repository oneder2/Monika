#!/bin/bash

# Monika 快速部署脚本 - 使用现有镜像

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

echo "🚀 Monika 快速部署脚本"
echo "====================="

# 检查现有镜像
log_info "检查现有镜像..."
if docker images | grep -q "monika-backend.*latest"; then
    log_success "找到后端镜像"
    backend_image="monika-backend:latest"
elif docker images | grep -q "your-username/monika-backend"; then
    log_success "找到后端镜像（带仓库前缀）"
    backend_image=$(docker images | grep "your-username/monika-backend" | head -1 | awk '{print $1":"$2}')
else
    log_error "未找到后端镜像"
    exit 1
fi

if docker images | grep -q "monika-frontend.*latest"; then
    log_success "找到前端镜像"
    frontend_image="monika-frontend:latest"
elif docker images | grep -q "your-username/monika-frontend"; then
    log_success "找到前端镜像（带仓库前缀）"
    frontend_image=$(docker images | grep "your-username/monika-frontend" | head -1 | awk '{print $1":"$2}')
else
    log_error "未找到前端镜像"
    exit 1
fi

log_info "使用镜像:"
echo "  后端: $backend_image"
echo "  前端: $frontend_image"

# 创建本地 docker-compose 文件
log_info "创建本地部署配置..."
cat > docker-compose.local.yml << EOF
services:
  # 后端服务
  backend:
    image: $backend_image
    container_name: monika-backend-local
    restart: unless-stopped
    environment:
      - PYTHONPATH=/app
      - DATABASE_URL=sqlite:///./data/monika.db
      - SECRET_KEY=local-development-secret-key-change-in-production
      - ACCESS_TOKEN_EXPIRE_MINUTES=1440
      - ENVIRONMENT=local
    volumes:
      - ./data:/app/data
      - ./logs:/app/logs
    ports:
      - "8000:8000"
    networks:
      - monika-network
    healthcheck:
      test: ["CMD", "python", "-c", "import requests; requests.get('http://localhost:8000/health')"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # 前端服务
  frontend:
    image: $frontend_image
    container_name: monika-frontend-local
    restart: unless-stopped
    ports:
      - "8080:80"
    depends_on:
      backend:
        condition: service_healthy
    networks:
      - monika-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  monika-network:
    driver: bridge

volumes:
  monika-data:
    driver: local
EOF

# 创建必要目录
log_info "创建数据目录..."
mkdir -p data logs

# 停止现有服务
log_info "停止现有服务..."
docker compose -f docker-compose.local.yml down 2>/dev/null || true
docker compose down 2>/dev/null || true

# 启动服务
log_info "启动 Monika 服务..."
docker compose -f docker-compose.local.yml up -d

# 等待服务启动
log_info "等待服务启动..."
sleep 10

# 检查服务状态
log_info "检查服务状态..."
if docker compose -f docker-compose.local.yml ps | grep -q "Up"; then
    log_success "服务启动成功！"
    
    # 显示服务状态
    echo ""
    echo "=== 服务状态 ==="
    docker compose -f docker-compose.local.yml ps
    
    echo ""
    echo "=== 访问地址 ==="
    echo "🌐 前端应用: http://localhost:8080"
    echo "🔧 后端 API: http://localhost:8000"
    echo "📚 API 文档: http://localhost:8000/docs"
    echo "❤️  健康检查: http://localhost:8000/health"
    
    echo ""
    echo "=== 管理命令 ==="
    echo "查看日志: docker compose -f docker-compose.local.yml logs -f"
    echo "重启服务: docker compose -f docker-compose.local.yml restart"
    echo "停止服务: docker compose -f docker-compose.local.yml down"
    
    # 测试健康检查
    echo ""
    log_info "测试服务健康状态..."
    sleep 5
    
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        log_success "后端服务健康检查通过"
    else
        log_warning "后端服务健康检查失败，请稍等片刻再试"
    fi
    
    if curl -f http://localhost:8080 > /dev/null 2>&1; then
        log_success "前端服务健康检查通过"
    else
        log_warning "前端服务健康检查失败，请稍等片刻再试"
    fi
    
else
    log_error "服务启动失败"
    echo ""
    echo "=== 错误日志 ==="
    docker compose -f docker-compose.local.yml logs
    exit 1
fi

echo ""
log_success "🎉 Monika 快速部署完成！"
echo ""
echo "💡 提示:"
echo "- 这是本地部署版本，数据存储在 ./data 目录"
echo "- 日志存储在 ./logs 目录"
echo "- 如需生产环境部署，请配置 Docker 仓库后使用 ./deploy/deploy.sh"
