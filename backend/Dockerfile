# 使用Python 3.12官方镜像作为基础镜像
FROM python:3.12-slim

# 设置构建参数
ARG BUILD_DATE
ARG GIT_COMMIT

# 设置标签
LABEL maintainer="Monika Team" \
      version="1.0" \
      description="Monika Backend Service" \
      build-date=$BUILD_DATE \
      git-commit=$GIT_COMMIT

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app:/app/backend \
    ENVIRONMENT=production

# 创建非特权用户
RUN groupadd -r monika && useradd -r -g monika monika

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 复制requirements文件
COPY requirements.txt .

# 安装Python依赖
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY . .

# 创建必要目录并设置权限
RUN mkdir -p /app/data /app/logs \
    && chown -R monika:monika /app

# 切换到非特权用户
USER monika

# 暴露端口
EXPOSE 8000

# 健康检查
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# 启动命令
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
