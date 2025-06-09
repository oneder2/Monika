from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
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

# 添加验证错误处理器
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    print(f"Validation error: {exc.errors()}")
    # 安全地处理错误信息，避免序列化问题
    error_details = []
    for error in exc.errors():
        safe_error = {
            "type": error.get("type"),
            "loc": error.get("loc"),
            "msg": error.get("msg"),
            "input": str(error.get("input")) if error.get("input") is not None else None
        }
        error_details.append(safe_error)

    return JSONResponse(
        status_code=422,
        content={"detail": error_details}
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
