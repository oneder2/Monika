from sqlalchemy.orm import Session
from typing import List, Optional
from backend.models.models import User, Account, Project, Category, Transaction, Tag, Budget
from backend.schemas.schemas import (
    UserCreate, UserUpdate, AccountCreate, AccountUpdate,
    ProjectCreate, ProjectUpdate, CategoryCreate, CategoryUpdate,
    TransactionCreate, TransactionUpdate, TagCreate, TagUpdate,
    BudgetCreate, BudgetUpdate
)
from backend.auth.auth import get_password_hash


# User CRUD
def get_user(db: Session, user_id: int) -> Optional[User]:
    return db.query(User).filter(User.id == user_id).first()


def get_user_by_email(db: Session, email: str) -> Optional[User]:
    return db.query(User).filter(User.email == email).first()


def get_user_by_username(db: Session, username: str) -> Optional[User]:
    return db.query(User).filter(User.username == username).first()


def create_user(db: Session, user: UserCreate) -> User:
    hashed_password = get_password_hash(user.password)
    db_user = User(
        username=user.username,
        email=user.email,
        password_hash=hashed_password,
        default_currency=user.default_currency
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


def update_user(db: Session, user_id: int, user_update: UserUpdate) -> Optional[User]:
    db_user = get_user(db, user_id)
    if db_user:
        update_data = user_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_user, field, value)
        db.commit()
        db.refresh(db_user)
    return db_user


# Account CRUD
def get_accounts(db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[Account]:
    return db.query(Account).filter(Account.user_id == user_id).offset(skip).limit(limit).all()


def get_account(db: Session, account_id: int, user_id: int) -> Optional[Account]:
    return db.query(Account).filter(Account.id == account_id, Account.user_id == user_id).first()


def create_account(db: Session, account: AccountCreate, user_id: int) -> Account:
    db_account = Account(**account.dict(), user_id=user_id)
    db.add(db_account)
    db.commit()
    db.refresh(db_account)
    return db_account


def update_account(db: Session, account_id: int, user_id: int, account_update: AccountUpdate) -> Optional[Account]:
    db_account = get_account(db, account_id, user_id)
    if db_account:
        update_data = account_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_account, field, value)
        db.commit()
        db.refresh(db_account)
    return db_account


def delete_account(db: Session, account_id: int, user_id: int) -> bool:
    db_account = get_account(db, account_id, user_id)
    if db_account:
        db.delete(db_account)
        db.commit()
        return True
    return False


# Project CRUD
def get_projects(db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[Project]:
    return db.query(Project).filter(Project.user_id == user_id).offset(skip).limit(limit).all()


def get_project(db: Session, project_id: int, user_id: int) -> Optional[Project]:
    return db.query(Project).filter(Project.id == project_id, Project.user_id == user_id).first()


def create_project(db: Session, project: ProjectCreate, user_id: int) -> Project:
    db_project = Project(**project.dict(), user_id=user_id)
    db.add(db_project)
    db.commit()
    db.refresh(db_project)
    return db_project


def update_project(db: Session, project_id: int, user_id: int, project_update: ProjectUpdate) -> Optional[Project]:
    db_project = get_project(db, project_id, user_id)
    if db_project:
        update_data = project_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_project, field, value)
        db.commit()
        db.refresh(db_project)
    return db_project


def delete_project(db: Session, project_id: int, user_id: int) -> bool:
    db_project = get_project(db, project_id, user_id)
    if db_project:
        db.delete(db_project)
        db.commit()
        return True
    return False


# Category CRUD
def get_categories(db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[Category]:
    return db.query(Category).filter(
        (Category.user_id == user_id) | (Category.user_id.is_(None))
    ).offset(skip).limit(limit).all()


def get_category(db: Session, category_id: int, user_id: int) -> Optional[Category]:
    return db.query(Category).filter(
        Category.id == category_id,
        (Category.user_id == user_id) | (Category.user_id.is_(None))
    ).first()


def create_category(db: Session, category: CategoryCreate, user_id: int) -> Category:
    db_category = Category(**category.dict(), user_id=user_id)
    db.add(db_category)
    db.commit()
    db.refresh(db_category)
    return db_category


def update_category(db: Session, category_id: int, user_id: int, category_update: CategoryUpdate) -> Optional[Category]:
    db_category = db.query(Category).filter(
        Category.id == category_id, Category.user_id == user_id
    ).first()
    if db_category:
        update_data = category_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_category, field, value)
        db.commit()
        db.refresh(db_category)
    return db_category


def delete_category(db: Session, category_id: int, user_id: int) -> bool:
    db_category = db.query(Category).filter(
        Category.id == category_id, Category.user_id == user_id
    ).first()
    if db_category:
        db.delete(db_category)
        db.commit()
        return True
    return False


# Transaction CRUD
def get_transactions(db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[Transaction]:
    return db.query(Transaction).filter(Transaction.user_id == user_id).offset(skip).limit(limit).all()


def get_transaction(db: Session, transaction_id: int, user_id: int) -> Optional[Transaction]:
    return db.query(Transaction).filter(Transaction.id == transaction_id, Transaction.user_id == user_id).first()


def create_transaction(db: Session, transaction: TransactionCreate, user_id: int) -> Transaction:
    transaction_data = transaction.dict()
    tag_ids = transaction_data.pop('tag_ids', [])

    db_transaction = Transaction(**transaction_data, user_id=user_id)
    db.add(db_transaction)
    db.commit()
    db.refresh(db_transaction)

    # 添加标签关联
    if tag_ids:
        tags = db.query(Tag).filter(Tag.id.in_(tag_ids), Tag.user_id == user_id).all()
        db_transaction.tags.extend(tags)
        db.commit()

    return db_transaction


def update_transaction(db: Session, transaction_id: int, user_id: int, transaction_update: TransactionUpdate) -> Optional[Transaction]:
    db_transaction = get_transaction(db, transaction_id, user_id)
    if db_transaction:
        update_data = transaction_update.dict(exclude_unset=True)
        tag_ids = update_data.pop('tag_ids', None)

        for field, value in update_data.items():
            setattr(db_transaction, field, value)

        # 更新标签关联
        if tag_ids is not None:
            db_transaction.tags.clear()
            if tag_ids:
                tags = db.query(Tag).filter(Tag.id.in_(tag_ids), Tag.user_id == user_id).all()
                db_transaction.tags.extend(tags)

        db.commit()
        db.refresh(db_transaction)
    return db_transaction


def delete_transaction(db: Session, transaction_id: int, user_id: int) -> bool:
    db_transaction = get_transaction(db, transaction_id, user_id)
    if db_transaction:
        db.delete(db_transaction)
        db.commit()
        return True
    return False


# Tag CRUD
def get_tags(db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[Tag]:
    return db.query(Tag).filter(Tag.user_id == user_id).offset(skip).limit(limit).all()


def get_tag(db: Session, tag_id: int, user_id: int) -> Optional[Tag]:
    return db.query(Tag).filter(Tag.id == tag_id, Tag.user_id == user_id).first()


def create_tag(db: Session, tag: TagCreate, user_id: int) -> Tag:
    db_tag = Tag(**tag.dict(), user_id=user_id)
    db.add(db_tag)
    db.commit()
    db.refresh(db_tag)
    return db_tag


def update_tag(db: Session, tag_id: int, user_id: int, tag_update: TagUpdate) -> Optional[Tag]:
    db_tag = get_tag(db, tag_id, user_id)
    if db_tag:
        update_data = tag_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_tag, field, value)
        db.commit()
        db.refresh(db_tag)
    return db_tag


def delete_tag(db: Session, tag_id: int, user_id: int) -> bool:
    db_tag = get_tag(db, tag_id, user_id)
    if db_tag:
        db.delete(db_tag)
        db.commit()
        return True
    return False


# Budget CRUD
def get_budgets(db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[Budget]:
    return db.query(Budget).filter(Budget.user_id == user_id).offset(skip).limit(limit).all()


def get_budget(db: Session, budget_id: int, user_id: int) -> Optional[Budget]:
    return db.query(Budget).filter(Budget.id == budget_id, Budget.user_id == user_id).first()


def create_budget(db: Session, budget: BudgetCreate, user_id: int) -> Budget:
    db_budget = Budget(**budget.dict(), user_id=user_id)
    db.add(db_budget)
    db.commit()
    db.refresh(db_budget)
    return db_budget


def update_budget(db: Session, budget_id: int, user_id: int, budget_update: BudgetUpdate) -> Optional[Budget]:
    db_budget = get_budget(db, budget_id, user_id)
    if db_budget:
        update_data = budget_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_budget, field, value)
        db.commit()
        db.refresh(db_budget)
    return db_budget


def delete_budget(db: Session, budget_id: int, user_id: int) -> bool:
    db_budget = get_budget(db, budget_id, user_id)
    if db_budget:
        db.delete(db_budget)
        db.commit()
        return True
    return False
