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
