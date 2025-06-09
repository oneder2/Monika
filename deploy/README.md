# Monika 项目部署指南

## 🚀 标准部署流程

本目录包含 Monika 项目的完整生产环境部署解决方案，支持从构建到部署的全自动化流程。

## 📁 文件结构

```
deploy/
├── deploy.sh                    # 一键部署脚本（推荐）
├── build-and-push.sh           # 构建和推送镜像脚本
├── deploy-to-production.sh     # 生产环境部署脚本
├── docker-compose.prod.yml     # 生产环境 Docker Compose 配置
├── nginx.prod.conf             # 生产环境 Nginx 配置
├── .env.production.example     # 生产环境变量示例
└── README.md                   # 本文档
```

## 🛠️ 部署前准备

### 1. 环境要求

**本地环境:**
- Docker 20.10+
- Docker Compose 2.0+
- Git
- SSH 客户端

**生产服务器:**
- Docker 20.10+
- Docker Compose 2.0+
- SSH 服务
- 足够的磁盘空间（建议 10GB+）

### 2. 配置文件准备

```bash
# 复制环境变量示例文件
cp deploy/.env.production.example deploy/.env.production

# 编辑配置文件
vim deploy/.env.production
```

**必须修改的配置项:**
```bash
# Docker 镜像仓库
DOCKER_REGISTRY=docker.io/your-username

# 生产服务器信息
PRODUCTION_SERVER=your-production-server.com
DEPLOY_USER=deploy
DEPLOY_PATH=/opt/monika

# 安全密钥（重要！）
SECRET_KEY=your-super-secret-key-here

# Docker Hub 认证（如果使用私有仓库）
DOCKER_USERNAME=your-docker-username
DOCKER_PASSWORD=your-docker-password
```

### 3. SSH 密钥配置

```bash
# 生成 SSH 密钥（如果没有）
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# 复制公钥到生产服务器
ssh-copy-id deploy@your-production-server.com

# 测试连接
ssh deploy@your-production-server.com "echo 'SSH connection successful'"
```

### 4. 生产服务器准备

```bash
# 在生产服务器上创建部署用户
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy

# 创建部署目录
sudo mkdir -p /opt/monika
sudo chown deploy:deploy /opt/monika
```

## 🚀 部署方法

### 方法 1: 一键部署（推荐）

```bash
# 使用默认配置部署最新版本
./deploy/deploy.sh

# 部署指定版本到指定服务器
./deploy/deploy.sh v1.0.0 production.example.com

# 使用环境变量
PRODUCTION_SERVER=prod.example.com ./deploy/deploy.sh latest
```

### 方法 2: 分步部署

#### 步骤 1: 构建和推送镜像

```bash
# 构建并推送最新版本
./deploy/build-and-push.sh

# 构建并推送指定版本
./deploy/build-and-push.sh v1.0.0
```

#### 步骤 2: 部署到生产环境

```bash
# 部署最新版本
./deploy/deploy-to-production.sh

# 部署指定版本到指定服务器
./deploy/deploy-to-production.sh v1.0.0 production.example.com
```

## 🔧 部署流程详解

### 1. 构建阶段
- 检查 Git 状态和分支
- 构建后端 Docker 镜像
- 构建前端 Docker 镜像
- 推送镜像到容器仓库

### 2. 部署阶段
- 连接生产服务器
- 备份当前部署和数据
- 上传部署配置文件
- 拉取最新镜像
- 停止旧服务并启动新服务
- 执行健康检查
- 清理旧镜像

### 3. 验证阶段
- 后端 API 健康检查
- 前端服务可用性检查
- 服务状态监控

## 📊 部署后管理

### 查看服务状态

```bash
# 连接到生产服务器
ssh deploy@your-production-server.com

# 查看容器状态
cd /opt/monika
docker compose -f docker-compose.prod.yml ps

# 查看服务日志
docker compose -f docker-compose.prod.yml logs -f

# 查看特定服务日志
docker compose -f docker-compose.prod.yml logs -f backend
docker compose -f docker-compose.prod.yml logs -f frontend
```

### 服务管理命令

```bash
# 重启服务
docker compose -f docker-compose.prod.yml restart

# 停止服务
docker compose -f docker-compose.prod.yml down

# 启动服务
docker compose -f docker-compose.prod.yml up -d

# 更新服务（拉取最新镜像）
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

### 数据备份

```bash
# 手动备份数据库
docker compose -f docker-compose.prod.yml --profile backup run --rm db-backup

# 查看备份文件
ls -la backups/

# 设置定时备份（crontab）
echo "0 2 * * * cd /opt/monika && docker compose -f docker-compose.prod.yml --profile backup run --rm db-backup" | crontab -
```

## 🔒 安全配置

### 1. 防火墙设置

```bash
# 只开放必要端口
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw enable
```

### 2. SSL/HTTPS 配置

```bash
# 安装 Certbot（Let's Encrypt）
sudo apt install certbot

# 获取 SSL 证书
sudo certbot certonly --standalone -d your-domain.com

# 配置 SSL（编辑 nginx.prod.conf）
# 取消注释 HTTPS server 配置块
```

### 3. 定期更新

```bash
# 设置自动安全更新
sudo apt install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades
```

## 🚨 故障排除

### 常见问题

#### 1. 构建失败
```bash
# 检查 Docker 服务状态
sudo systemctl status docker

# 清理 Docker 缓存
docker system prune -a

# 重新构建
./deploy/build-and-push.sh
```

#### 2. 部署失败
```bash
# 检查服务器连接
ssh deploy@your-production-server.com

# 检查磁盘空间
df -h

# 检查 Docker 状态
docker ps -a
docker compose -f docker-compose.prod.yml logs
```

#### 3. 服务无法访问
```bash
# 检查端口监听
netstat -tlnp | grep :80
netstat -tlnp | grep :8000

# 检查防火墙
sudo ufw status

# 检查容器网络
docker network ls
docker network inspect monika_monika-network
```

### 回滚操作

```bash
# 自动回滚（部署脚本失败时会自动执行）
# 手动回滚到上一个版本
cd /opt/monika
latest_backup=$(ls -1t backups/deployment-* | head -n1)
cp -r "$latest_backup"/* .
docker compose -f docker-compose.prod.yml up -d
```

## 📈 监控和日志

### 1. 日志管理

```bash
# 实时查看日志
docker compose -f docker-compose.prod.yml logs -f

# 查看特定时间段日志
docker compose -f docker-compose.prod.yml logs --since="2024-01-01T00:00:00Z"

# 日志轮转配置
# 编辑 /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

### 2. 性能监控

```bash
# 查看资源使用情况
docker stats

# 查看磁盘使用
docker system df

# 查看镜像大小
docker images
```

## 🔄 CI/CD 集成

### GitHub Actions 示例

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to Production
      env:
        DOCKER_REGISTRY: ${{ secrets.DOCKER_REGISTRY }}
        DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
        DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
        PRODUCTION_SERVER: ${{ secrets.PRODUCTION_SERVER }}
        DEPLOY_USER: ${{ secrets.DEPLOY_USER }}
        SECRET_KEY: ${{ secrets.SECRET_KEY }}
      run: |
        ./deploy/deploy.sh ${GITHUB_REF#refs/tags/}
```

## 📞 支持和帮助

如果在部署过程中遇到问题：

1. 查看本文档的故障排除部分
2. 检查服务日志：`docker compose -f docker-compose.prod.yml logs`
3. 查看项目 Issues：[GitHub Issues](https://github.com/your-username/monika/issues)
4. 联系项目维护者

---

**注意**: 在生产环境部署前，请务必在测试环境中验证所有配置和流程。
