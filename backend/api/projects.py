from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from backend.database.database import get_db
from backend.schemas.schemas import Project, ProjectCreate, ProjectUpdate
from backend.crud.crud import (
    get_projects, get_project, create_project, 
    update_project, delete_project
)
from backend.auth.auth import get_current_active_user
from backend.models.models import User

router = APIRouter(prefix="/projects", tags=["projects"])


@router.get("/", response_model=List[Project])
def read_projects(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """获取用户的所有项目"""
    projects = get_projects(db, user_id=current_user.id, skip=skip, limit=limit)
    return projects


@router.post("/", response_model=Project)
def create_project_for_user(
    project: ProjectCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """创建新项目"""
    return create_project(db=db, project=project, user_id=current_user.id)


@router.get("/{project_id}", response_model=Project)
def read_project(
    project_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """获取特定项目"""
    db_project = get_project(db, project_id=project_id, user_id=current_user.id)
    if db_project is None:
        raise HTTPException(status_code=404, detail="Project not found")
    return db_project


@router.put("/{project_id}", response_model=Project)
def update_project_for_user(
    project_id: int,
    project_update: ProjectUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """更新项目"""
    db_project = update_project(db, project_id=project_id, user_id=current_user.id, project_update=project_update)
    if db_project is None:
        raise HTTPException(status_code=404, detail="Project not found")
    return db_project


@router.delete("/{project_id}")
def delete_project_for_user(
    project_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """删除项目"""
    success = delete_project(db, project_id=project_id, user_id=current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Project not found")
    return {"message": "Project deleted successfully"}
