# Monika 下一步开发指南

## 🎯 当前开发建议：标签系统 (v1.1)

### 为什么选择标签系统作为下一步？

1. **用户价值高**: 标签系统能显著提升数据组织和查询能力
2. **技术难度适中**: 适合作为第一个新功能开发
3. **扩展性强**: 为后续功能（如智能分析）奠定基础
4. **开发周期短**: 预计 1-2 周完成

## 🛠️ 开发环境准备

### 1. 设置开发环境

```bash
# 1. 停止 Docker 容器（如果正在运行）
docker compose down

# 2. 设置后端开发环境
cd backend
python -m venv venv
source venv/bin/activate  # Linux/Mac
# 或 venv\Scripts\activate  # Windows

pip install -r requirements.txt

# 3. 设置前端开发环境
cd ../frontend
npm install

# 4. 启动开发服务器
# 终端1: 启动后端
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 终端2: 启动前端
cd frontend
npm run dev
```

### 2. 开发工具推荐

- **IDE**: VS Code 或 PyCharm
- **数据库工具**: SQLite Browser 或 DBeaver
- **API 测试**: Postman 或使用 FastAPI 自动文档
- **版本控制**: Git

## 📋 标签系统开发计划

### 阶段 1: 后端开发 (3-4 天)

#### 1.1 数据模型设计

```python
# backend/models/models.py 中添加

class Tag(Base):
    __tablename__ = "tags"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(50), nullable=False)
    color = Column(String(7), default="#007bff")  # 十六进制颜色
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # 关系
    user = relationship("User", back_populates="tags")
    transactions = relationship("Transaction", secondary="transaction_tags", back_populates="tags")

class TransactionTag(Base):
    __tablename__ = "transaction_tags"
    
    transaction_id = Column(Integer, ForeignKey("transactions.id"), primary_key=True)
    tag_id = Column(Integer, ForeignKey("tags.id"), primary_key=True)
```

#### 1.2 Pydantic 模式

```python
# backend/schemas/schemas.py 中添加

class TagBase(BaseModel):
    name: str
    color: Optional[str] = "#007bff"

class TagCreate(TagBase):
    pass

class TagUpdate(TagBase):
    name: Optional[str] = None

class Tag(TagBase):
    id: int
    user_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class TransactionWithTags(TransactionBase):
    tags: List[Tag] = []
```

#### 1.3 CRUD 操作

```python
# backend/crud/crud.py 中添加

def create_tag(db: Session, tag: TagCreate, user_id: int):
    db_tag = Tag(**tag.dict(), user_id=user_id)
    db.add(db_tag)
    db.commit()
    db.refresh(db_tag)
    return db_tag

def get_tags(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return db.query(Tag).filter(Tag.user_id == user_id).offset(skip).limit(limit).all()

def add_tags_to_transaction(db: Session, transaction_id: int, tag_ids: List[int], user_id: int):
    # 验证标签属于当前用户
    tags = db.query(Tag).filter(Tag.id.in_(tag_ids), Tag.user_id == user_id).all()
    transaction = db.query(Transaction).filter(Transaction.id == transaction_id, Transaction.user_id == user_id).first()
    
    if transaction:
        transaction.tags = tags
        db.commit()
    return transaction
```

#### 1.4 API 路由

```python
# backend/api/tags.py (新文件)

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

router = APIRouter()

@router.post("/", response_model=Tag)
def create_tag(tag: TagCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return crud.create_tag(db=db, tag=tag, user_id=current_user.id)

@router.get("/", response_model=List[Tag])
def read_tags(skip: int = 0, limit: int = 100, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return crud.get_tags(db, user_id=current_user.id, skip=skip, limit=limit)

@router.post("/transactions/{transaction_id}/tags/")
def add_tags_to_transaction(transaction_id: int, tag_ids: List[int], db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return crud.add_tags_to_transaction(db, transaction_id, tag_ids, current_user.id)
```

### 阶段 2: 前端开发 (3-4 天)

#### 2.1 标签管理组件

```vue
<!-- frontend/src/components/TagManager.vue -->
<template>
  <div class="tag-manager">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>标签管理</span>
          <el-button type="primary" @click="showCreateDialog = true">
            <el-icon><Plus /></el-icon>
            新建标签
          </el-button>
        </div>
      </template>
      
      <el-table :data="tags" style="width: 100%">
        <el-table-column prop="name" label="标签名称" />
        <el-table-column prop="color" label="颜色">
          <template #default="scope">
            <el-color-picker v-model="scope.row.color" @change="updateTag(scope.row)" />
          </template>
        </el-table-column>
        <el-table-column label="操作">
          <template #default="scope">
            <el-button size="small" @click="editTag(scope.row)">编辑</el-button>
            <el-button size="small" type="danger" @click="deleteTag(scope.row.id)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
    
    <!-- 创建/编辑对话框 -->
    <el-dialog v-model="showCreateDialog" title="创建标签">
      <el-form :model="tagForm" label-width="80px">
        <el-form-item label="标签名称">
          <el-input v-model="tagForm.name" />
        </el-form-item>
        <el-form-item label="颜色">
          <el-color-picker v-model="tagForm.color" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showCreateDialog = false">取消</el-button>
        <el-button type="primary" @click="createTag">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>
```

#### 2.2 标签选择组件

```vue
<!-- frontend/src/components/TagSelector.vue -->
<template>
  <div class="tag-selector">
    <el-select
      v-model="selectedTags"
      multiple
      filterable
      allow-create
      placeholder="选择或创建标签"
      @change="$emit('update:modelValue', selectedTags)"
    >
      <el-option
        v-for="tag in tags"
        :key="tag.id"
        :label="tag.name"
        :value="tag.id"
      >
        <span :style="{ color: tag.color }">{{ tag.name }}</span>
      </el-option>
    </el-select>
    
    <!-- 已选标签显示 -->
    <div class="selected-tags" v-if="selectedTagObjects.length">
      <el-tag
        v-for="tag in selectedTagObjects"
        :key="tag.id"
        :color="tag.color"
        closable
        @close="removeTag(tag.id)"
      >
        {{ tag.name }}
      </el-tag>
    </div>
  </div>
</template>
```

### 阶段 3: 集成和测试 (1-2 天)

#### 3.1 更新交易表单
- 在创建/编辑交易时添加标签选择
- 在交易列表中显示标签
- 支持按标签筛选交易

#### 3.2 测试清单
- [ ] 标签 CRUD 操作
- [ ] 交易-标签关联
- [ ] 标签筛选功能
- [ ] 标签颜色显示
- [ ] 权限验证（用户只能操作自己的标签）

## 🔧 开发最佳实践

### 1. 版本控制
```bash
# 创建功能分支
git checkout -b feature/tag-system

# 提交代码
git add .
git commit -m "feat: add tag system backend models"

# 推送分支
git push origin feature/tag-system
```

### 2. 测试驱动开发
```python
# backend/tests/test_tags.py
def test_create_tag():
    # 测试标签创建
    pass

def test_add_tags_to_transaction():
    # 测试为交易添加标签
    pass
```

### 3. API 文档
- 使用 FastAPI 自动生成的文档测试 API
- 访问 http://localhost:8000/docs

## 📚 学习资源

### 后端相关
- [SQLAlchemy 多对多关系](https://docs.sqlalchemy.org/en/14/orm/basic_relationships.html#many-to-many)
- [FastAPI 依赖注入](https://fastapi.tiangolo.com/tutorial/dependencies/)

### 前端相关
- [Element Plus 表格组件](https://element-plus.org/zh-CN/component/table.html)
- [Vue 3 组合式 API](https://vuejs.org/guide/extras/composition-api-faq.html)

## 🎯 完成标准

标签系统开发完成的标准：

1. ✅ 用户可以创建、编辑、删除标签
2. ✅ 标签支持自定义颜色
3. ✅ 交易记录可以添加多个标签
4. ✅ 支持按标签筛选交易
5. ✅ 标签在界面中正确显示
6. ✅ 所有功能通过测试
7. ✅ API 文档更新

## 🚀 后续开发建议

完成标签系统后，建议按以下顺序继续开发：

1. **v1.2 预算管理系统** - 核心财务功能
2. **v1.3 数据可视化** - 提升用户体验
3. **性能优化** - 提升系统稳定性

每个功能都可以按照类似的开发流程进行。
