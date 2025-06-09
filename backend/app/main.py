from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.database.database import engine
from backend.models import models
from backend.api import auth, users, accounts, projects, transactions

# 创建数据库表
models.Base.metadata.create_all(bind=engine)

# 创建FastAPI应用
app = FastAPI(
    title="Monika - 个人记账软件",
    description="基于FastAPI + Vue.js + SQLite的个人记账软件",
    version="1.0.0"
)

# 配置CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000"],  # Vue.js开发服务器
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 包含路由
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(accounts.router)
app.include_router(projects.router)
app.include_router(transactions.router)


@app.get("/")
def read_root():
    return {"message": "Welcome to Monika - Personal Finance Management System"}


@app.get("/health")
def health_check():
    return {"status": "healthy"}
