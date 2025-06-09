from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from backend.database.database import get_db
from backend.schemas.schemas import Account, AccountCreate, AccountUpdate
from backend.crud.crud import (
    get_accounts, get_account, create_account, 
    update_account, delete_account
)
from backend.auth.auth import get_current_active_user
from backend.models.models import User

router = APIRouter(prefix="/accounts", tags=["accounts"])


@router.get("/", response_model=List[Account])
def read_accounts(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """获取用户的所有账户"""
    accounts = get_accounts(db, user_id=current_user.id, skip=skip, limit=limit)
    return accounts


@router.post("/", response_model=Account)
def create_account_for_user(
    account: AccountCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """创建新账户"""
    return create_account(db=db, account=account, user_id=current_user.id)


@router.get("/{account_id}", response_model=Account)
def read_account(
    account_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """获取特定账户"""
    db_account = get_account(db, account_id=account_id, user_id=current_user.id)
    if db_account is None:
        raise HTTPException(status_code=404, detail="Account not found")
    return db_account


@router.put("/{account_id}", response_model=Account)
def update_account_for_user(
    account_id: int,
    account_update: AccountUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """更新账户"""
    db_account = update_account(db, account_id=account_id, user_id=current_user.id, account_update=account_update)
    if db_account is None:
        raise HTTPException(status_code=404, detail="Account not found")
    return db_account


@router.delete("/{account_id}")
def delete_account_for_user(
    account_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """删除账户"""
    success = delete_account(db, account_id=account_id, user_id=current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Account not found")
    return {"message": "Account deleted successfully"}
