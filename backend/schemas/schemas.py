from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, date


# User schemas
class UserBase(BaseModel):
    username: str
    email: str
    default_currency: str = "CNY"


class UserCreate(UserBase):
    password: str


class UserUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None
    default_currency: Optional[str] = None


class User(UserBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


# Account schemas
class AccountBase(BaseModel):
    name: str
    type: str
    initial_balance: float = 0.00
    is_active: bool = True


class AccountCreate(AccountBase):
    pass


class AccountUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[str] = None
    initial_balance: Optional[float] = None
    is_active: Optional[bool] = None


class Account(AccountBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True


# Project schemas
class ProjectBase(BaseModel):
    name: str
    description: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None


class ProjectCreate(ProjectBase):
    pass


class ProjectUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None


class Project(ProjectBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True


# Category schemas
class CategoryBase(BaseModel):
    name: str
    type: str  # 'income' 或 'expense'
    parent_category_id: Optional[int] = None
    icon_name: Optional[str] = None


class CategoryCreate(CategoryBase):
    pass


class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[str] = None
    parent_category_id: Optional[int] = None
    icon_name: Optional[str] = None


class Category(CategoryBase):
    id: int
    user_id: Optional[int] = None

    class Config:
        from_attributes = True


# Transaction schemas
class TransactionBase(BaseModel):
    account_id: int
    project_id: Optional[int] = None
    category_id: Optional[int] = None
    type: str  # 'income' 或 'expense'
    title: Optional[str] = None
    amount: float
    currency: str
    transaction_date: datetime
    notes: Optional[str] = None


class TransactionCreate(TransactionBase):
    tag_ids: Optional[List[int]] = []


class TransactionUpdate(BaseModel):
    account_id: Optional[int] = None
    project_id: Optional[int] = None
    category_id: Optional[int] = None
    type: Optional[str] = None
    title: Optional[str] = None
    amount: Optional[float] = None
    currency: Optional[str] = None
    transaction_date: Optional[datetime] = None
    notes: Optional[str] = None
    tag_ids: Optional[List[int]] = None


class Transaction(TransactionBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True


# Tag schemas
class TagBase(BaseModel):
    name: str


class TagCreate(TagBase):
    pass


class TagUpdate(BaseModel):
    name: Optional[str] = None


class Tag(TagBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True


# Budget schemas
class BudgetBase(BaseModel):
    category_id: Optional[int] = None
    amount: float
    period: str
    start_date: date


class BudgetCreate(BudgetBase):
    pass


class BudgetUpdate(BaseModel):
    category_id: Optional[int] = None
    amount: Optional[float] = None
    period: Optional[str] = None
    start_date: Optional[date] = None


class Budget(BudgetBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True


# Authentication schemas
class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    username: Optional[str] = None
