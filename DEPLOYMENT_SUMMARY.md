# Monika 项目标准部署流程总结

## 🎯 部署流程概述

我已经为 Monika 项目创建了完整的标准部署流程，包含从构建到生产环境部署的全自动化解决方案。

## 📁 部署文件结构

```
deploy/
├── deploy.sh                    # 🚀 一键部署脚本（推荐使用）
├── build-and-push.sh           # 🔨 构建和推送镜像脚本
├── deploy-to-production.sh     # 🌐 生产环境部署脚本
├── check-deployment.sh         # 🔍 部署状态检查脚本
├── docker-compose.prod.yml     # 🐳 生产环境 Docker Compose 配置
├── nginx.prod.conf             # ⚙️ 生产环境 Nginx 配置
├── .env.production.example     # 📝 生产环境变量示例
└── README.md                   # 📚 详细部署文档
```

## 🚀 标准部署流程

### 流程 1: 基于 main 分支构建生产环境 Docker 镜像

```bash
# 自动检查 Git 状态，构建并推送镜像
./deploy/build-and-push.sh [tag]

# 流程包括：
# 1. 检查 Git 分支和状态
# 2. 构建后端和前端 Docker 镜像
# 3. 添加构建标签和元数据
# 4. 推送镜像到容器仓库
```

### 流程 2: 将新镜像推送到容器镜像仓库

```bash
# 支持多种容器仓库
export DOCKER_REGISTRY="docker.io/your-username"  # Docker Hub
# 或
export DOCKER_REGISTRY="ghcr.io/your-username"    # GitHub Container Registry
# 或
export DOCKER_REGISTRY="your-registry.com"        # 私有仓库

# 自动登录和推送
./deploy/build-and-push.sh v1.0.0
```

### 流程 3: 连接生产服务器并重启服务

```bash
# 完整的生产环境部署
./deploy/deploy-to-production.sh [tag] [server]

# 流程包括：
# 1. 连接生产服务器
# 2. 备份当前部署和数据
# 3. 上传新的配置文件
# 4. 拉取最新镜像
# 5. 停止旧服务，启动新服务
# 6. 执行健康检查
# 7. 清理旧镜像
```

## 🎯 一键部署（推荐）

```bash
# 执行完整的部署流程
./deploy/deploy.sh [tag] [server]

# 示例：
./deploy/deploy.sh v1.0.0 production.example.com

# 或使用环境变量：
PRODUCTION_SERVER=prod.example.com ./deploy/deploy.sh latest
```

## ⚙️ 部署前配置

### 1. 环境变量配置

```bash
# 复制配置模板
cp deploy/.env.production.example deploy/.env.production

# 编辑配置文件
vim deploy/.env.production
```

**必须配置的关键项：**
```bash
DOCKER_REGISTRY=docker.io/your-username
PRODUCTION_SERVER=your-production-server.com
SECRET_KEY=your-super-secret-key-here
DEPLOY_USER=deploy
DEPLOY_PATH=/opt/monika
```

### 2. SSH 密钥配置

```bash
# 生成 SSH 密钥
ssh-keygen -t rsa -b 4096

# 复制到生产服务器
ssh-copy-id deploy@your-production-server.com

# 测试连接
ssh deploy@your-production-server.com "echo 'Connection successful'"
```

### 3. 生产服务器准备

```bash
# 在生产服务器上执行
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy
sudo mkdir -p /opt/monika
sudo chown deploy:deploy /opt/monika
```

## 🔧 部署特性

### 安全性
- ✅ 非特权用户运行容器
- ✅ 安全的环境变量管理
- ✅ 自动备份机制
- ✅ 健康检查和故障恢复

### 可靠性
- ✅ 自动回滚机制
- ✅ 部署前备份
- ✅ 服务健康检查
- ✅ 错误处理和日志记录

### 可维护性
- ✅ 详细的部署日志
- ✅ 状态检查脚本
- ✅ 清理旧镜像
- ✅ 配置文件管理

## 📊 部署后管理

### 状态检查

```bash
# 检查部署状态
./deploy/check-deployment.sh your-server.com

# 生成状态报告
./deploy/check-deployment.sh > status-report.txt
```

### 服务管理

```bash
# 连接到生产服务器
ssh deploy@your-production-server.com

# 查看服务状态
cd /opt/monika
docker compose -f docker-compose.prod.yml ps

# 查看日志
docker compose -f docker-compose.prod.yml logs -f

# 重启服务
docker compose -f docker-compose.prod.yml restart
```

### 数据备份

```bash
# 手动备份
ssh deploy@your-server.com "cd /opt/monika && docker compose -f docker-compose.prod.yml --profile backup run --rm db-backup"

# 自动备份（crontab）
echo "0 2 * * * cd /opt/monika && docker compose -f docker-compose.prod.yml --profile backup run --rm db-backup" | crontab -
```

## 🔍 监控和故障排除

### 健康检查端点
- **后端健康检查**: `http://your-server:8000/health`
- **前端可用性**: `http://your-server/`
- **API 文档**: `http://your-server:8000/docs`

### 常见问题解决

```bash
# 1. 服务无法启动
docker compose -f docker-compose.prod.yml logs
docker compose -f docker-compose.prod.yml ps

# 2. 磁盘空间不足
docker system prune -a
docker volume prune

# 3. 网络问题
netstat -tlnp | grep :80
sudo ufw status

# 4. 回滚到上一版本
cd /opt/monika
latest_backup=$(ls -1t backups/deployment-* | head -n1)
cp -r "$latest_backup"/* .
docker compose -f docker-compose.prod.yml up -d
```

## 🔄 CI/CD 集成

### GitHub Actions 示例

```yaml
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
    - name: Deploy
      env:
        PRODUCTION_SERVER: ${{ secrets.PRODUCTION_SERVER }}
        DOCKER_REGISTRY: ${{ secrets.DOCKER_REGISTRY }}
        SECRET_KEY: ${{ secrets.SECRET_KEY }}
      run: ./deploy/deploy.sh ${GITHUB_REF#refs/tags/}
```

## 📈 性能优化

### 生产环境优化
- ✅ 多阶段 Docker 构建
- ✅ Nginx 静态文件缓存
- ✅ Gzip 压缩
- ✅ 健康检查机制
- ✅ 资源限制配置

### 镜像优化
- ✅ 最小化镜像大小
- ✅ 分层缓存优化
- ✅ 安全扫描
- ✅ 构建元数据

## 🎯 部署验证清单

### 部署前检查
- [ ] 配置文件已正确设置
- [ ] SSH 密钥已配置
- [ ] 生产服务器环境已准备
- [ ] Docker 仓库访问正常

### 部署后验证
- [ ] 所有容器正常运行
- [ ] 健康检查通过
- [ ] 前端页面可访问
- [ ] API 接口正常
- [ ] 数据库连接正常
- [ ] 备份机制工作

## 🚀 快速开始

1. **配置环境**
   ```bash
   cp deploy/.env.production.example deploy/.env.production
   # 编辑配置文件
   ```

2. **执行部署**
   ```bash
   ./deploy/deploy.sh v1.0.0 your-server.com
   ```

3. **验证部署**
   ```bash
   ./deploy/check-deployment.sh your-server.com
   ```

4. **访问应用**
   - 前端: http://your-server.com
   - API: http://your-server.com:8000/docs

## 📞 支持

如果在部署过程中遇到问题：

1. 查看 [部署文档](deploy/README.md)
2. 运行状态检查脚本
3. 查看服务日志
4. 联系项目维护者

---

**Monika 项目现已具备完整的生产环境部署能力，支持从开发到生产的全流程自动化部署！** 🎉
