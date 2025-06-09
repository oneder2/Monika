from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from backend.database.database import get_db
from backend.schemas.schemas import User, UserUpdate
from backend.crud.crud import get_user, update_user
from backend.auth.auth import get_current_active_user
from backend.models.models import User as UserModel

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me/", response_model=User)
def read_users_me(current_user: UserModel = Depends(get_current_active_user)):
    """获取当前用户信息"""
    return current_user


@router.put("/me/", response_model=User)
def update_user_me(
    user_update: UserUpdate,
    current_user: UserModel = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """更新当前用户信息"""
    updated_user = update_user(db, current_user.id, user_update)
    if not updated_user:
        raise HTTPException(status_code=404, detail="User not found")
    return updated_user
