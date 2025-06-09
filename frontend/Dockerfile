# 多阶段构建 - 构建阶段
FROM node:18-alpine AS builder

# 设置构建参数
ARG BUILD_DATE
ARG GIT_COMMIT

# 设置工作目录
WORKDIR /app

# 复制package文件
COPY package*.json ./

# 安装依赖（包括开发依赖，用于构建）
RUN npm ci --silent

# 复制源代码
COPY . .

# 构建应用
RUN npm run build

# 生产阶段 - 使用nginx提供静态文件服务
FROM nginx:alpine

# 设置标签
LABEL maintainer="Monika Team" \
      version="1.0" \
      description="Monika Frontend Service" \
      build-date=$BUILD_DATE \
      git-commit=$GIT_COMMIT

# 安装curl用于健康检查
RUN apk add --no-cache curl

# 复制构建产物到nginx目录
COPY --from=builder /app/dist /usr/share/nginx/html

# 复制nginx配置文件
COPY nginx.conf /etc/nginx/nginx.conf

# 创建必要目录并设置权限
RUN mkdir -p /var/log/nginx /var/cache/nginx \
    && chown -R nginx:nginx /var/log/nginx /var/cache/nginx /usr/share/nginx/html

# 暴露端口
EXPOSE 80

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# 启动nginx
CMD ["nginx", "-g", "daemon off;"]
