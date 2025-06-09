# Monika Docker 部署指南

## 🐳 Docker 容器化概述

Monika 项目已完全容器化，支持一键部署到开发和生产环境。使用 Docker 和 Docker Compose 可以确保在任何支持 Docker 的环境中都能稳定运行。

## 📋 系统要求

- Docker 20.10+
- Docker Compose 2.0+
- 至少 2GB 可用内存
- 至少 5GB 可用磁盘空间

## 🚀 快速开始

### 1. 克隆项目并进入目录
```bash
git clone <repository-url>
cd Monika
```

### 2. 配置环境变量
```bash
# 复制环境变量模板
cp .env.example .env

# 编辑环境变量（重要：修改 SECRET_KEY）
nano .env
```

### 3. 一键部署
```bash
# 开发环境部署
./deploy.sh dev

# 生产环境部署
./deploy.sh prod
```

## 🛠️ 详细部署说明

### 开发环境部署

开发环境适用于本地开发和测试：

```bash
# 使用部署脚本
./deploy.sh dev

# 或手动执行
docker-compose up --build -d
```

**访问地址：**
- 前端应用：http://localhost
- 后端API：http://localhost:8000
- API文档：http://localhost:8000/docs

### 生产环境部署

生产环境包含优化配置和安全设置：

```bash
# 使用部署脚本
./deploy.sh prod

# 或手动执行
docker-compose -f docker-compose.prod.yml up --build -d
```

**生产环境特性：**
- 资源限制和预留
- 自动重启策略
- 健康检查
- 数据持久化
- 安全配置

## 📁 项目结构

```
Monika/
├── backend/
│   ├── Dockerfile              # 后端容器配置
│   ├── requirements.txt        # Python依赖
│   └── .dockerignore          # Docker忽略文件
├── frontend/
│   ├── Dockerfile             # 前端容器配置
│   ├── nginx.conf             # Nginx配置
│   └── .dockerignore          # Docker忽略文件
├── docker-compose.yml         # 开发环境配置
├── docker-compose.prod.yml    # 生产环境配置
├── deploy.sh                  # 部署脚本
├── .env.example              # 环境变量模板
└── DOCKER_DEPLOYMENT.md      # 本文档
```

## ⚙️ 环境变量配置

关键环境变量说明：

| 变量名 | 说明 | 默认值 | 必需 |
|--------|------|--------|------|
| `SECRET_KEY` | JWT密钥（生产环境必须修改） | - | ✅ |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Token过期时间（分钟） | 1440 | ❌ |
| `FRONTEND_PORT` | 前端端口 | 80 | ❌ |
| `ENVIRONMENT` | 运行环境 | development | ❌ |
| `DATABASE_URL` | 数据库连接字符串 | sqlite:///./data/monika.db | ❌ |

## 🔧 常用命令

### 部署脚本命令
```bash
./deploy.sh dev      # 开发环境部署
./deploy.sh prod     # 生产环境部署
./deploy.sh backup   # 数据库备份
./deploy.sh logs     # 查看日志
./deploy.sh stop     # 停止服务
./deploy.sh cleanup  # 清理资源
```

### Docker Compose 命令
```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f [service_name]

# 重启服务
docker-compose restart [service_name]

# 进入容器
docker-compose exec backend bash
docker-compose exec frontend sh

# 停止并删除容器
docker-compose down --remove-orphans
```

## 💾 数据管理

### 数据持久化
- 数据库文件存储在 `./data/monika.db`
- 生产环境使用 Docker volume 确保数据安全

### 数据备份
```bash
# 手动备份
./deploy.sh backup

# 自动备份（生产环境）
docker-compose -f docker-compose.prod.yml --profile backup up -d backup-scheduler
```

### 数据恢复
```bash
# 停止服务
./deploy.sh stop

# 恢复数据库文件
cp backups/monika-backup-YYYYMMDD-HHMMSS.db data/monika.db

# 重启服务
./deploy.sh prod
```

## 🔒 安全配置

### 生产环境安全建议

1. **修改默认密钥**
   ```bash
   # 生成安全的密钥
   openssl rand -hex 32
   ```

2. **使用HTTPS**
   - 配置SSL证书
   - 启用nginx-proxy服务

3. **网络安全**
   - 使用防火墙限制端口访问
   - 配置反向代理

4. **定期备份**
   - 启用自动备份
   - 定期测试恢复流程

## 🐛 故障排除

### 常见问题

1. **端口冲突**
   ```bash
   # 检查端口占用
   netstat -tulpn | grep :80
   netstat -tulpn | grep :8000
   
   # 修改端口配置
   nano .env  # 修改 FRONTEND_PORT
   ```

2. **权限问题**
   ```bash
   # 确保脚本可执行
   chmod +x deploy.sh
   
   # 检查Docker权限
   sudo usermod -aG docker $USER
   ```

3. **容器启动失败**
   ```bash
   # 查看详细日志
   docker-compose logs backend
   docker-compose logs frontend
   
   # 检查容器状态
   docker-compose ps
   ```

4. **数据库问题**
   ```bash
   # 重新初始化数据库
   rm -f data/monika.db
   docker-compose restart backend
   ```

## 📊 监控和日志

### 健康检查
```bash
# 检查服务健康状态
curl http://localhost:8000/health

# 查看容器健康状态
docker-compose ps
```

### 日志管理
```bash
# 实时查看日志
./deploy.sh logs

# 查看特定服务日志
docker-compose logs -f backend
docker-compose logs -f frontend
```

## 🔄 更新和维护

### 应用更新
```bash
# 拉取最新代码
git pull

# 重新构建和部署
./deploy.sh prod
```

### 清理和维护
```bash
# 清理未使用的Docker资源
./deploy.sh cleanup

# 清理旧的备份文件（保留最近7天）
find backups/ -name "monika-backup-*.db" -mtime +7 -delete
```

## 📞 技术支持

如果遇到部署问题，请检查：
1. Docker和Docker Compose版本
2. 系统资源（内存、磁盘空间）
3. 网络连接和端口配置
4. 环境变量设置
5. 日志文件中的错误信息
