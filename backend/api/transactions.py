from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from backend.database.database import get_db
from backend.schemas.schemas import Transaction, TransactionCreate, TransactionUpdate
from backend.crud.crud import (
    get_transactions, get_transaction, create_transaction, 
    update_transaction, delete_transaction
)
from backend.auth.auth import get_current_active_user
from backend.models.models import User

router = APIRouter(prefix="/transactions", tags=["transactions"])


@router.get("/", response_model=List[Transaction])
def read_transactions(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """获取用户的所有交易记录"""
    transactions = get_transactions(db, user_id=current_user.id, skip=skip, limit=limit)
    return transactions


@router.post("/", response_model=Transaction)
def create_transaction_for_user(
    transaction: TransactionCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """创建新交易记录"""
    return create_transaction(db=db, transaction=transaction, user_id=current_user.id)


@router.get("/{transaction_id}", response_model=Transaction)
def read_transaction(
    transaction_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """获取特定交易记录"""
    db_transaction = get_transaction(db, transaction_id=transaction_id, user_id=current_user.id)
    if db_transaction is None:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return db_transaction


@router.put("/{transaction_id}", response_model=Transaction)
def update_transaction_for_user(
    transaction_id: int,
    transaction_update: TransactionUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """更新交易记录"""
    db_transaction = update_transaction(db, transaction_id=transaction_id, user_id=current_user.id, transaction_update=transaction_update)
    if db_transaction is None:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return db_transaction


@router.delete("/{transaction_id}")
def delete_transaction_for_user(
    transaction_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """删除交易记录"""
    success = delete_transaction(db, transaction_id=transaction_id, user_id=current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return {"message": "Transaction deleted successfully"}
