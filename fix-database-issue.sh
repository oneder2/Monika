#!/bin/bash

# 数据库权限问题修复脚本

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

echo "🔧 数据库权限问题修复脚本"
echo "========================"

# 停止现有服务
log_info "停止现有服务..."
docker compose -f docker-compose.simple.yml down 2>/dev/null || true

# 检查并创建数据目录
log_info "检查数据目录..."
if [ ! -d "data" ]; then
    mkdir -p data
    log_info "创建 data 目录"
fi

if [ ! -d "logs" ]; then
    mkdir -p logs
    log_info "创建 logs 目录"
fi

# 设置目录权限
log_info "设置目录权限..."
chmod 755 data logs
log_success "目录权限设置完成"

# 方案1: 使用 root 用户运行（简单但不够安全）
create_root_config() {
    log_info "创建 root 用户配置..."
    
    cat > docker-compose.root.yml << EOF
services:
  # 后端服务 (root 用户)
  backend:
    image: monika-backend:latest
    container_name: monika-backend-root
    restart: unless-stopped
    user: "0:0"  # root 用户
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

  # 前端服务
  frontend:
    image: monika-frontend:latest
    container_name: monika-frontend-root
    restart: unless-stopped
    ports:
      - "8080:80"
    depends_on:
      - backend
    networks:
      - monika-network

networks:
  monika-network:
    driver: bridge
EOF
    
    log_success "root 用户配置创建完成"
}

# 方案2: 修复权限映射
create_fixed_config() {
    log_info "创建权限修复配置..."
    
    # 获取当前用户的 UID 和 GID
    USER_ID=$(id -u)
    GROUP_ID=$(id -g)
    
    cat > docker-compose.fixed.yml << EOF
services:
  # 后端服务 (权限修复)
  backend:
    image: monika-backend:latest
    container_name: monika-backend-fixed
    restart: unless-stopped
    user: "${USER_ID}:${GROUP_ID}"
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

  # 前端服务
  frontend:
    image: monika-frontend:latest
    container_name: monika-frontend-fixed
    restart: unless-stopped
    ports:
      - "8080:80"
    depends_on:
      - backend
    networks:
      - monika-network

networks:
  monika-network:
    driver: bridge
EOF
    
    log_success "权限修复配置创建完成 (UID:$USER_ID, GID:$GROUP_ID)"
}

# 方案3: 使用内存数据库（临时解决方案）
create_memory_config() {
    log_info "创建内存数据库配置..."
    
    cat > docker-compose.memory.yml << EOF
services:
  # 后端服务 (内存数据库)
  backend:
    image: monika-backend:latest
    container_name: monika-backend-memory
    restart: unless-stopped
    environment:
      - PYTHONPATH=/app
      - DATABASE_URL=sqlite:///:memory:
      - SECRET_KEY=local-development-secret-key-change-in-production
      - ACCESS_TOKEN_EXPIRE_MINUTES=1440
      - ENVIRONMENT=local
    ports:
      - "8000:8000"
    networks:
      - monika-network

  # 前端服务
  frontend:
    image: monika-frontend:latest
    container_name: monika-frontend-memory
    restart: unless-stopped
    ports:
      - "8080:80"
    depends_on:
      - backend
    networks:
      - monika-network

networks:
  monika-network:
    driver: bridge
EOF
    
    log_warning "内存数据库配置创建完成 (数据不会持久化)"
}

# 显示解决方案选项
show_solutions() {
    echo ""
    log_info "请选择解决方案:"
    echo "1. 使用 root 用户运行 (简单，但安全性较低)"
    echo "2. 修复用户权限映射 (推荐)"
    echo "3. 使用内存数据库 (临时测试用)"
    echo "4. 查看详细错误信息"
    echo ""
    read -p "请选择 (1-4): " choice
    
    case $choice in
        1) 
            create_root_config
            test_solution "docker-compose.root.yml" "root 用户"
            ;;
        2) 
            create_fixed_config
            test_solution "docker-compose.fixed.yml" "权限修复"
            ;;
        3) 
            create_memory_config
            test_solution "docker-compose.memory.yml" "内存数据库"
            ;;
        4) 
            show_debug_info
            ;;
        *) 
            log_error "无效选择"
            exit 1
            ;;
    esac
}

# 测试解决方案
test_solution() {
    local config_file=$1
    local solution_name=$2
    
    log_info "测试 $solution_name 解决方案..."
    
    # 启动服务
    docker compose -f "$config_file" up -d
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 15
    
    # 检查服务状态
    if docker compose -f "$config_file" ps | grep -q "Up"; then
        log_success "服务启动成功！"
        
        # 测试健康检查
        if curl -f http://localhost:8000/health > /dev/null 2>&1; then
            log_success "✅ $solution_name 解决方案成功！"
            echo ""
            echo "服务访问地址:"
            echo "  前端: http://localhost:8080"
            echo "  后端: http://localhost:8000"
            echo "  API文档: http://localhost:8000/docs"
            echo ""
            echo "管理命令:"
            echo "  查看状态: docker compose -f $config_file ps"
            echo "  查看日志: docker compose -f $config_file logs -f"
            echo "  停止服务: docker compose -f $config_file down"
        else
            log_warning "服务启动但健康检查失败，查看日志..."
            docker compose -f "$config_file" logs backend | tail -10
        fi
    else
        log_error "$solution_name 解决方案失败"
        docker compose -f "$config_file" logs backend | tail -10
    fi
}

# 显示调试信息
show_debug_info() {
    log_info "收集调试信息..."
    
    echo ""
    echo "=== 系统信息 ==="
    echo "当前用户: $(whoami)"
    echo "用户 ID: $(id -u)"
    echo "组 ID: $(id -g)"
    echo "当前目录: $(pwd)"
    
    echo ""
    echo "=== 目录权限 ==="
    ls -la data/ logs/ 2>/dev/null || echo "目录不存在"
    
    echo ""
    echo "=== Docker 信息 ==="
    docker --version
    docker compose version
    
    echo ""
    echo "=== 镜像信息 ==="
    docker images | grep monika
    
    echo ""
    echo "=== 最近的错误日志 ==="
    docker compose -f docker-compose.simple.yml logs backend 2>/dev/null | tail -20 || echo "无法获取日志"
    
    echo ""
    log_info "调试信息收集完成"
    show_solutions
}

# 主函数
main() {
    show_solutions
}

# 运行主函数
main
