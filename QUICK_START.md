# 🚀 Monika 快速启动指南

## 📋 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- 2GB+ 可用内存
- 5GB+ 可用磁盘空间

## ⚡ 一键部署

### 1. 克隆并进入项目目录
```bash
git clone <repository-url>
cd Monika
```

### 2. 配置环境变量
```bash
# 复制环境变量模板
cp .env.example .env

# 编辑配置文件（重要：修改SECRET_KEY）
nano .env
```

### 3. 启动服务
```bash
# 开发环境（推荐用于测试）
./deploy.sh dev

# 生产环境
./deploy.sh prod
```

## 🌐 访问应用

部署完成后，访问以下地址：

- **前端应用**: http://localhost
- **后端API**: http://localhost:8000
- **API文档**: http://localhost:8000/docs

## 🔑 默认测试账户

- **用户名**: testuser
- **密码**: testpass123

## 📊 功能特性

✅ **已实现功能**
- 用户认证（注册/登录）
- 账户管理（多种账户类型）
- 项目管理（按项目分组）
- 交易记录管理
- 财务仪表盘
- 响应式设计

🚧 **待开发功能**
- 预算管理
- 标签系统
- 数据可视化图表
- 数据导入/导出

## 🛠️ 常用命令

```bash
# 查看服务状态
docker compose ps

# 查看日志
./deploy.sh logs

# 停止服务
./deploy.sh stop

# 备份数据
./deploy.sh backup

# 清理资源
./deploy.sh cleanup
```

## 🔧 故障排除

### 端口冲突
```bash
# 检查端口占用
netstat -tulpn | grep :80
netstat -tulpn | grep :8000

# 修改端口（编辑.env文件）
FRONTEND_PORT=8080
```

### 权限问题
```bash
# 确保脚本可执行
chmod +x deploy.sh

# 添加Docker权限
sudo usermod -aG docker $USER
```

### 容器启动失败
```bash
# 查看详细日志
docker compose logs backend
docker compose logs frontend

# 重新构建
docker compose up --build --force-recreate
```

## 📞 技术支持

如遇问题，请检查：
1. Docker和Docker Compose版本
2. 系统资源（内存、磁盘）
3. 网络连接和端口配置
4. 环境变量设置
5. 日志文件中的错误信息

详细文档请参考：[Docker部署指南](DOCKER_DEPLOYMENT.md)
