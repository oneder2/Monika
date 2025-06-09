# Monika 部署指南

## 🐳 Docker 部署（推荐）

### 前提条件
- Docker 20.10+
- Docker Compose 2.0+
- 2GB+ 可用内存

### 快速部署

1. 克隆项目到本地：
```bash
git clone https://github.com/your-username/monika.git
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

### 🔧 服务说明

#### 后端服务 (monika-backend)
- **端口**: 8000
- **技术栈**: FastAPI + SQLAlchemy + SQLite
- **功能**: 提供 RESTful API 服务
- **数据存储**: `./data` 目录

#### 前端服务 (monika-frontend)
- **端口**: 8080
- **技术栈**: Vue.js 3 + Vite + Nginx
- **功能**: 提供用户界面和静态文件服务

### 💾 数据持久化

数据库文件存储在主机的 `./data` 目录中，确保数据在容器重启后不会丢失。

```bash
# 数据目录结构
./data/
└── monika.db    # SQLite 数据库文件
```

### 🛠️ 常用命令

```bash
# 启动服务
docker compose up -d

# 停止服务
docker compose down

# 查看服务状态
docker compose ps

# 查看日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f backend
docker compose logs -f frontend

# 重新构建并启动
docker compose up -d --build

# 重启特定服务
docker compose restart backend
docker compose restart frontend
```

### 💾 数据备份

#### 手动备份
```bash
# 创建备份目录
mkdir -p backups

# 备份数据库文件
cp data/monika.db backups/monika-backup-$(date +%Y%m%d-%H%M%S).db
```

#### 使用内置备份服务
```bash
# 运行数据库备份
docker compose --profile backup run --rm db-backup
```

备份文件将保存在 `./backups` 目录中。

### 🔧 故障排除

#### 端口冲突
```bash
# 检查端口占用
netstat -tulpn | grep :8080
netstat -tulpn | grep :8000

# 修改端口映射（编辑 docker-compose.yml）
ports:
  - "8081:80"  # 将前端端口改为 8081
```

#### 权限问题
```bash
# 确保数据目录权限
chmod 755 data/
chown -R $USER:$USER data/
```

#### 容器启动失败
```bash
# 查看详细日志
docker compose logs backend
docker compose logs frontend

# 重新构建镜像
docker compose build --no-cache
docker compose up -d
```

### 🚀 生产环境建议

1. **安全配置**
   - 修改默认密钥和密码
   - 配置防火墙规则
   - 启用 HTTPS

2. **性能优化**
   - 配置反向代理（Nginx/Traefik）
   - 启用 Gzip 压缩
   - 配置缓存策略

3. **监控和维护**
   - 定期备份数据库
   - 监控容器健康状态
   - 设置日志轮转

## 💻 开发环境部署

如果需要在开发环境中运行（不使用 Docker）：

### 后端开发
```bash
cd backend

# 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Linux/Mac
# 或 venv\Scripts\activate  # Windows

# 安装依赖
pip install -r requirements.txt

# 启动开发服务器
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 前端开发
```bash
cd frontend

# 安装依赖
npm install

# 启动开发服务器
npm run dev
```

## 🔄 更新应用

### 更新到最新版本
```bash
# 1. 停止服务
docker compose down

# 2. 拉取最新代码
git pull origin main

# 3. 重新构建并启动
docker compose up -d --build
```

### 版本回滚
```bash
# 回滚到指定版本
git checkout v1.0.0
docker compose up -d --build
```

## ⚙️ 配置说明

### 主要配置文件
- `docker-compose.yml` - Docker Compose 服务编排
- `backend/Dockerfile` - 后端容器构建配置
- `frontend/Dockerfile` - 前端容器构建配置
- `frontend/nginx.conf` - Nginx Web 服务器配置

### 环境变量
可以通过环境变量自定义配置：

```bash
# 设置前端端口
export FRONTEND_PORT=8081

# 设置后端端口
export BACKEND_PORT=8001

# 启动服务
docker compose up -d
```

## 📚 相关文档

- [开发指南](docs/DEVELOPMENT.md) - 详细的开发说明
- [数据库设计](docs/DATABASE.md) - 数据库结构说明
- [项目路线图](docs/ROADMAP.md) - 未来开发计划
