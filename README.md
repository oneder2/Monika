# Monika - 个人记账软件

<div align="center">

![Monika Logo](https://img.shields.io/badge/Monika-Personal%20Finance-blue?style=for-the-badge)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Vue.js](https://img.shields.io/badge/Vue.js-4FC08D?style=for-the-badge&logo=vue.js&logoColor=white)](https://vuejs.org/)
[![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://www.sqlite.org/)

**一个现代化的个人财务管理工具**

[快速开始](#-快速开始) • [功能特性](#-功能特性) • [技术栈](#-技术栈) • [部署指南](#-部署指南) • [开发文档](#-开发文档)

</div>

---

## 📖 项目简介

**Monika** 是一个基于 Web 的个人记账软件，采用现代化的前后端分离架构，为用户提供轻量、高效且功能强大的财务管理体验。

### 🎯 设计理念

- **简洁易用**: 直观的用户界面，降低学习成本
- **数据安全**: 本地部署，数据完全掌控
- **高性能**: 异步架构，快速响应
- **可扩展**: 模块化设计，易于功能扩展

## 🚀 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- 2GB+ 可用内存

### 一键部署

```bash
# 1. 克隆项目
git clone https://github.com/your-username/monika.git
cd monika

# 2. 启动服务
docker compose up -d

# 3. 访问应用
# 前端: http://localhost:8080
# 后端API: http://localhost:8000
# API文档: http://localhost:8000/docs
```

详细部署说明请参考 [部署指南](DEPLOYMENT.md)

## ✨ 功能特性

### ✅ 已实现功能

- 🔐 **用户认证系统**
  - 安全的用户注册和登录
  - JWT Token 认证
  - 密码加密存储

- 💰 **账户管理**
  - 多种账户类型支持（储蓄卡、信用卡、现金等）
  - 账户余额跟踪
  - 账户状态管理

- 📊 **项目管理**
  - 按项目分组管理交易记录
  - 项目时间范围设定
  - 项目财务统计

- 💸 **交易记录管理**
  - 完整的收支记录 CRUD 操作
  - 交易分类和标注
  - 交易历史查询

- 📈 **财务仪表盘**
  - 收支概览统计
  - 账户余额展示
  - 最近交易记录

- 🏷️ **分类系统**
  - 收入/支出分类管理
  - 多级分类支持
  - 自定义分类图标

- 🐳 **Docker 容器化**
  - 一键部署
  - 开发/生产环境支持
  - 数据持久化

- 📱 **响应式设计**
  - 移动端适配
  - 现代化 UI 界面

### 🚧 计划中功能

- 💰 预算管理系统
- 🏷️ 标签系统
- 📊 高级数据可视化
- 📈 支出模式分析
- 📤 数据导入/导出
- 🔔 异常支出提醒
- 📊 财务报表生成

## 🛠️ 技术栈

### 后端
- **FastAPI**: 高性能异步 Web 框架
- **SQLAlchemy**: ORM 数据库操作
- **SQLite**: 轻量级数据库
- **Pydantic**: 数据验证和序列化
- **JWT**: 用户认证

### 前端
- **Vue.js 3**: 渐进式前端框架
- **Vite**: 现代化构建工具
- **Element Plus**: UI 组件库
- **Axios**: HTTP 客户端
- **Vue Router**: 路由管理

### 部署
- **Docker**: 容器化部署
- **Docker Compose**: 多容器编排
- **Nginx**: 静态文件服务

## 📁 项目结构

```
monika/
├── backend/                 # 后端代码
│   ├── app/                # FastAPI 应用
│   ├── api/                # API 路由
│   ├── auth/               # 认证模块
│   ├── crud/               # 数据库操作
│   ├── database/           # 数据库配置
│   ├── models/             # 数据模型
│   ├── schemas/            # Pydantic 模式
│   └── Dockerfile          # 后端容器配置
├── frontend/               # 前端代码
│   ├── src/                # Vue.js 源码
│   ├── public/             # 静态资源
│   └── Dockerfile          # 前端容器配置
├── data/                   # 数据持久化目录
├── docs/                   # 项目文档
├── docker-compose.yml      # Docker Compose 配置
├── DEPLOYMENT.md           # 部署指南
└── README.md              # 项目说明
```

## 🚀 部署指南

### Docker 部署（推荐）

详细部署说明请参考 [DEPLOYMENT.md](DEPLOYMENT.md)

### 开发环境

#### 后端开发
```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

#### 前端开发
```bash
cd frontend
npm install
npm run dev
```

## 📚 开发文档

- [API 文档](http://localhost:8000/docs) - 自动生成的 API 文档
- [开发指南](docs/DEVELOPMENT.md) - 详细的开发说明
- [数据库设计](docs/DATABASE.md) - 数据库结构说明
- [部署指南](DEPLOYMENT.md) - 完整的部署说明

## 🤝 贡献指南

欢迎贡献代码！请遵循以下步骤：

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 📞 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 [Issue](https://github.com/your-username/monika/issues)
- 发送邮件至 your-email@example.com

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给它一个星标！**

Made with ❤️ by [Your Name]

</div>