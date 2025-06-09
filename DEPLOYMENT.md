# Monika 部署指南

## Docker 部署

### 前提条件
- 安装 Docker 和 Docker Compose
- 确保端口 8000 和 8080 可用

### 快速部署

1. 克隆项目到本地：
```bash
git clone <repository-url>
cd monika
```

2. 启动服务：
```bash
docker compose up -d
```

3. 访问应用：
- 前端界面：http://localhost:8080
- 后端API：http://localhost:8000
- API文档：http://localhost:8000/docs

### 服务说明

#### 后端服务 (monika-backend)
- 端口：8000
- 基于 FastAPI 的 Python 后端
- 使用 SQLite 数据库
- 数据存储在 `./data` 目录

#### 前端服务 (monika-frontend)
- 端口：8080
- 基于 Vue.js 的前端应用
- 使用 Nginx 提供静态文件服务

### 数据持久化

数据库文件存储在主机的 `./data` 目录中，确保数据在容器重启后不会丢失。

### 常用命令

```bash
# 启动服务
docker compose up -d

# 停止服务
docker compose down

# 查看服务状态
docker compose ps

# 查看日志
docker compose logs

# 查看特定服务日志
docker compose logs backend
docker compose logs frontend

# 重新构建并启动
docker compose up -d --build
```

### 数据备份

可以使用内置的备份服务：

```bash
# 运行数据库备份
docker compose --profile backup run --rm db-backup
```

备份文件将保存在 `./backups` 目录中。

### 故障排除

1. **端口冲突**：如果端口 8080 被占用，可以修改 `docker-compose.yml` 中的端口映射

2. **权限问题**：确保 `./data` 目录有正确的读写权限

3. **容器启动失败**：检查日志 `docker compose logs`

### 生产环境建议

1. 使用环境变量管理敏感配置
2. 配置反向代理（如 Nginx）
3. 启用 HTTPS
4. 定期备份数据库
5. 监控容器健康状态

## 开发环境

如果需要在开发环境中运行：

### 后端开发
```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 前端开发
```bash
cd frontend
npm install
npm run dev
```

## 更新应用

1. 拉取最新代码
2. 重新构建并启动容器：
```bash
docker compose down
docker compose up -d --build
```

## 配置说明

主要配置文件：
- `docker-compose.yml`：Docker Compose 配置
- `backend/Dockerfile`：后端容器配置
- `frontend/Dockerfile`：前端容器配置
- `frontend/nginx.conf`：Nginx 配置
