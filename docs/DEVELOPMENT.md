# Monika 开发指南

## 📋 开发环境设置

### 前置要求

- Python 3.8+
- Node.js 16+
- Docker 20.10+
- Git

### 项目克隆

```bash
git clone https://github.com/your-username/monika.git
cd monika
```

## 🔧 后端开发

### 环境设置

```bash
cd backend

# 创建虚拟环境
python -m venv venv

# 激活虚拟环境
# Windows
venv\Scripts\activate
# Linux/Mac
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt
```

### 数据库初始化

```bash
# 数据库会在首次运行时自动创建
# 位置: backend/data/monika.db
```

### 启动开发服务器

```bash
# 在 backend 目录下
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

访问地址：
- API: http://localhost:8000
- 文档: http://localhost:8000/docs

### 后端项目结构

```
backend/
├── app/
│   └── main.py              # FastAPI 应用入口
├── api/                     # API 路由
│   ├── auth.py             # 认证相关
│   ├── users.py            # 用户管理
│   ├── accounts.py         # 账户管理
│   ├── projects.py         # 项目管理
│   └── transactions.py     # 交易记录
├── auth/
│   └── auth.py             # 认证逻辑
├── crud/
│   └── crud.py             # 数据库操作
├── database/
│   └── database.py         # 数据库配置
├── models/
│   └── models.py           # 数据模型
├── schemas/
│   └── schemas.py          # Pydantic 模式
└── requirements.txt        # Python 依赖
```

## 🎨 前端开发

### 环境设置

```bash
cd frontend

# 安装依赖
npm install
```

### 启动开发服务器

```bash
npm run dev
```

访问地址：http://localhost:3000

### 前端项目结构

```
frontend/
├── src/
│   ├── components/         # Vue 组件
│   ├── views/             # 页面组件
│   ├── router/            # 路由配置
│   ├── stores/            # Pinia 状态管理
│   ├── api/               # API 调用
│   ├── utils/             # 工具函数
│   └── main.js            # 应用入口
├── public/                # 静态资源
├── package.json           # 依赖配置
└── vite.config.js         # Vite 配置
```

## 🗄️ 数据库开发

### 模型修改

1. 修改 `backend/models/models.py`
2. 重启后端服务（SQLAlchemy 会自动创建表）

### 数据迁移

目前使用 SQLite，表结构变更会自动应用。生产环境建议使用 Alembic 进行迁移管理。

## 🔌 API 开发

### 添加新的 API 端点

1. 在 `backend/schemas/schemas.py` 中定义 Pydantic 模式
2. 在 `backend/crud/crud.py` 中添加数据库操作函数
3. 在相应的 `backend/api/*.py` 文件中添加路由
4. 在 `backend/app/main.py` 中注册路由

### API 设计规范

- 遵循 RESTful 设计原则
- 使用适当的 HTTP 状态码
- 提供清晰的错误信息
- 使用 Pydantic 进行数据验证

## 🧪 测试

### 后端测试

```bash
cd backend
pytest
```

### 前端测试

```bash
cd frontend
npm run test
```

## 🚀 部署开发

### 本地 Docker 开发

```bash
# 构建并启动
docker compose up --build

# 仅启动特定服务
docker compose up backend
docker compose up frontend
```

### 环境变量

开发环境变量配置：

```bash
# .env.development
SECRET_KEY=your-secret-key-for-development
ACCESS_TOKEN_EXPIRE_MINUTES=1440
DATABASE_URL=sqlite:///./data/monika.db
ENVIRONMENT=development
```

## 📝 代码规范

### Python 代码规范

- 使用 Black 进行代码格式化
- 使用 isort 进行导入排序
- 遵循 PEP 8 规范
- 添加类型提示

```bash
# 格式化代码
black backend/
isort backend/
```

### JavaScript 代码规范

- 使用 ESLint 进行代码检查
- 使用 Prettier 进行代码格式化
- 遵循 Vue.js 官方风格指南

```bash
# 代码检查和格式化
npm run lint
npm run format
```

## 🔍 调试技巧

### 后端调试

1. 使用 FastAPI 自动生成的文档进行 API 测试
2. 查看控制台日志输出
3. 使用 Python 调试器 (pdb)

### 前端调试

1. 使用浏览器开发者工具
2. 查看 Vue DevTools
3. 检查网络请求

## 📚 学习资源

### 后端相关

- [FastAPI 官方文档](https://fastapi.tiangolo.com/)
- [SQLAlchemy 文档](https://docs.sqlalchemy.org/)
- [Pydantic 文档](https://pydantic-docs.helpmanual.io/)

### 前端相关

- [Vue.js 官方文档](https://vuejs.org/)
- [Vite 文档](https://vitejs.dev/)
- [Pinia 文档](https://pinia.vuejs.org/)

## 🤝 贡献流程

1. 创建功能分支
2. 编写代码和测试
3. 确保代码通过所有检查
4. 提交 Pull Request
5. 代码审查
6. 合并到主分支

## 📞 开发支持

如果在开发过程中遇到问题：

1. 查看项目文档
2. 搜索已有的 Issues
3. 创建新的 Issue 描述问题
4. 联系项目维护者
