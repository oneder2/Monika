from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey, Text, Date
from sqlalchemy.types import DECIMAL
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    default_currency = Column(String(3), nullable=False, default="CNY")
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # 关系
    accounts = relationship("Account", back_populates="user")
    projects = relationship("Project", back_populates="user")
    categories = relationship("Category", back_populates="user")
    transactions = relationship("Transaction", back_populates="user")
    tags = relationship("Tag", back_populates="user")
    budgets = relationship("Budget", back_populates="user")


class Account(Base):
    __tablename__ = "accounts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(100), nullable=False)
    type = Column(String(20), nullable=False)  # 'debit_card', 'credit_card', 'cash', etc.
    initial_balance = Column(DECIMAL(10, 2), nullable=False, default=0.00)
    is_active = Column(Boolean, nullable=False, default=True)

    # 关系
    user = relationship("User", back_populates="accounts")
    transactions = relationship("Transaction", back_populates="account")


class Project(Base):
    __tablename__ = "projects"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(100), nullable=False)
    description = Column(Text)
    start_date = Column(Date)
    end_date = Column(Date)

    # 关系
    user = relationship("User", back_populates="projects")
    transactions = relationship("Transaction", back_populates="project")


class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)  # NULL为系统预设分类
    parent_category_id = Column(Integer, ForeignKey("categories.id"), nullable=True)
    name = Column(String(50), nullable=False)
    type = Column(String(10), nullable=False)  # 'income' 或 'expense'
    icon_name = Column(String(50))

    # 关系
    user = relationship("User", back_populates="categories")
    parent_category = relationship("Category", remote_side=[id])
    transactions = relationship("Transaction", back_populates="category")
    budgets = relationship("Budget", back_populates="category")


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    account_id = Column(Integer, ForeignKey("accounts.id"), nullable=False)
    project_id = Column(Integer, ForeignKey("projects.id"), nullable=True)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=True)
    type = Column(String(10), nullable=False)  # 'income' 或 'expense'
    title = Column(String(255))
    amount = Column(DECIMAL(10, 2), nullable=False)
    currency = Column(String(3), nullable=False)
    transaction_date = Column(DateTime(timezone=True), nullable=False)
    notes = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # 关系
    user = relationship("User", back_populates="transactions")
    account = relationship("Account", back_populates="transactions")
    project = relationship("Project", back_populates="transactions")
    category = relationship("Category", back_populates="transactions")
    tags = relationship("Tag", secondary="transaction_tags", back_populates="transactions")


class Tag(Base):
    __tablename__ = "tags"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(50), nullable=False)

    # 关系
    user = relationship("User", back_populates="tags")
    transactions = relationship("Transaction", secondary="transaction_tags", back_populates="tags")


class TransactionTag(Base):
    __tablename__ = "transaction_tags"

    transaction_id = Column(Integer, ForeignKey("transactions.id"), primary_key=True)
    tag_id = Column(Integer, ForeignKey("tags.id"), primary_key=True)


class Budget(Base):
    __tablename__ = "budgets"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=True)  # NULL为总预算
    amount = Column(DECIMAL(10, 2), nullable=False)
    period = Column(String(20), nullable=False)  # 'monthly', 'yearly', etc.
    start_date = Column(Date, nullable=False)

    # 关系
    user = relationship("User", back_populates="budgets")
    category = relationship("Category", back_populates="budgets")
