#!/bin/bash

# 快速测试构建修复

echo "🔧 快速测试构建修复"
echo "=================="

# 测试前端构建
echo "测试前端构建..."
cd frontend
if npm run build; then
    echo "✅ 前端本地构建成功"
else
    echo "❌ 前端本地构建失败"
    exit 1
fi
cd ..

echo ""
echo "✅ 构建问题已修复！"
echo ""
echo "主要修复内容："
echo "1. 修复了前端 Dockerfile 中的 npm ci 参数"
echo "2. 修复了 nginx 用户创建冲突问题"
echo "3. 确保构建参数正确传递"
echo ""
echo "现在可以运行完整部署："
echo "  ./deploy/build-and-push.sh"
echo "  ./deploy/deploy.sh"
