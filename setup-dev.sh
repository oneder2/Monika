#!/bin/bash

# Monika 开发环境设置脚本
# 使用方法: ./setup-dev.sh

echo "🚀 Monika 开发环境设置开始..."

# 检查必要的工具
check_requirements() {
    echo "📋 检查系统要求..."
    
    # 检查 Python
    if ! command -v python3 &> /dev/null; then
        echo "❌ Python 3 未安装，请先安装 Python 3.8+"
        exit 1
    fi
    
    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        echo "❌ Node.js 未安装，请先安装 Node.js 16+"
        exit 1
    fi
    
    # 检查 npm
    if ! command -v npm &> /dev/null; then
        echo "❌ npm 未安装，请先安装 npm"
        exit 1
    fi
    
    echo "✅ 系统要求检查通过"
}

# 停止 Docker 容器
stop_docker() {
    echo "🐳 停止 Docker 容器..."
    if command -v docker-compose &> /dev/null || command -v docker &> /dev/null; then
        docker compose down 2>/dev/null || docker-compose down 2>/dev/null || true
        echo "✅ Docker 容器已停止"
    else
        echo "ℹ️  Docker 未安装或未运行，跳过"
    fi
}

# 设置后端开发环境
setup_backend() {
    echo "🔧 设置后端开发环境..."
    
    cd backend
    
    # 创建虚拟环境
    if [ ! -d "venv" ]; then
        echo "📦 创建 Python 虚拟环境..."
        python3 -m venv venv
    fi
    
    # 激活虚拟环境并安装依赖
    echo "📦 安装 Python 依赖..."
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    
    echo "✅ 后端环境设置完成"
    cd ..
}

# 设置前端开发环境
setup_frontend() {
    echo "🎨 设置前端开发环境..."
    
    cd frontend
    
    # 安装依赖
    echo "📦 安装 Node.js 依赖..."
    npm install
    
    echo "✅ 前端环境设置完成"
    cd ..
}

# 创建开发启动脚本
create_dev_scripts() {
    echo "📝 创建开发启动脚本..."
    
    # 后端启动脚本
    cat > start-backend.sh << 'EOF'
#!/bin/bash
echo "🚀 启动后端开发服务器..."
cd backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
EOF
    
    # 前端启动脚本
    cat > start-frontend.sh << 'EOF'
#!/bin/bash
echo "🎨 启动前端开发服务器..."
cd frontend
npm run dev
EOF
    
    # 使脚本可执行
    chmod +x start-backend.sh
    chmod +x start-frontend.sh
    
    echo "✅ 开发启动脚本创建完成"
}

# 创建开发指南
create_dev_guide() {
    cat > DEV_QUICK_START.md << 'EOF'
# 开发环境快速启动指南

## 🚀 启动开发服务器

### 方法 1: 使用启动脚本（推荐）

```bash
# 启动后端（终端1）
./start-backend.sh

# 启动前端（终端2）
./start-frontend.sh
```

### 方法 2: 手动启动

```bash
# 启动后端
cd backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 启动前端（新终端）
cd frontend
npm run dev
```

## 🌐 访问地址

- **前端开发服务器**: http://localhost:3000
- **后端 API**: http://localhost:8000
- **API 文档**: http://localhost:8000/docs

## 🛠️ 开发工具

### 推荐的 VS Code 扩展

```bash
# 安装推荐扩展
code --install-extension ms-python.python
code --install-extension ms-vscode.vscode-typescript-next
code --install-extension Vue.volar
code --install-extension bradlc.vscode-tailwindcss
```

### 数据库工具

- **SQLite Browser**: 查看和编辑 SQLite 数据库
- **DBeaver**: 通用数据库工具

## 📋 下一步开发

参考 [下一步开发指南](docs/NEXT_DEVELOPMENT_GUIDE.md) 开始标签系统开发。

## 🔧 常见问题

### 端口冲突
如果端口被占用，可以修改端口：

```bash
# 后端使用其他端口
uvicorn app.main:app --reload --host 0.0.0.0 --port 8001

# 前端使用其他端口
npm run dev -- --port 3001
```

### 虚拟环境问题
```bash
# 重新创建虚拟环境
rm -rf backend/venv
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```
EOF
    
    echo "✅ 开发指南创建完成"
}

# 显示完成信息
show_completion() {
    echo ""
    echo "🎉 开发环境设置完成！"
    echo ""
    echo "📚 接下来的步骤："
    echo "1. 阅读开发指南: cat DEV_QUICK_START.md"
    echo "2. 启动后端: ./start-backend.sh"
    echo "3. 启动前端: ./start-frontend.sh"
    echo "4. 开始开发: 参考 docs/NEXT_DEVELOPMENT_GUIDE.md"
    echo ""
    echo "🌐 开发服务器地址:"
    echo "- 前端: http://localhost:3000"
    echo "- 后端: http://localhost:8000"
    echo "- API文档: http://localhost:8000/docs"
    echo ""
    echo "💡 提示: 使用两个终端分别启动前后端服务"
}

# 主函数
main() {
    check_requirements
    stop_docker
    setup_backend
    setup_frontend
    create_dev_scripts
    create_dev_guide
    show_completion
}

# 运行主函数
main
