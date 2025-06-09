# 标签系统开发模板

## 📋 开发检查清单

### 后端开发 (Day 1-4)

#### Day 1: 数据模型
- [ ] 在 `backend/models/models.py` 中添加 Tag 模型
- [ ] 在 `backend/models/models.py` 中添加 TransactionTag 关联表
- [ ] 更新 Transaction 模型，添加 tags 关系
- [ ] 更新 User 模型，添加 tags 关系
- [ ] 测试数据库模型创建

#### Day 2: API 模式和 CRUD
- [ ] 在 `backend/schemas/schemas.py` 中添加标签相关模式
- [ ] 在 `backend/crud/crud.py` 中添加标签 CRUD 操作
- [ ] 添加交易-标签关联的 CRUD 操作
- [ ] 编写单元测试

#### Day 3: API 路由
- [ ] 创建 `backend/api/tags.py` 路由文件
- [ ] 实现标签的增删改查 API
- [ ] 实现交易标签关联 API
- [ ] 在 `backend/app/main.py` 中注册路由

#### Day 4: 后端测试和优化
- [ ] 使用 Postman 或 FastAPI docs 测试所有 API
- [ ] 添加错误处理和验证
- [ ] 优化查询性能
- [ ] 编写 API 文档

### 前端开发 (Day 5-7)

#### Day 5: 基础组件
- [ ] 创建 `frontend/src/components/TagManager.vue`
- [ ] 创建 `frontend/src/components/TagSelector.vue`
- [ ] 创建 `frontend/src/components/TagDisplay.vue`
- [ ] 添加标签相关的 API 调用函数

#### Day 6: 页面集成
- [ ] 在交易表单中集成标签选择器
- [ ] 在交易列表中显示标签
- [ ] 添加标签管理页面
- [ ] 实现标签筛选功能

#### Day 7: 前端测试和优化
- [ ] 测试所有标签相关功能
- [ ] 优化用户体验
- [ ] 添加加载状态和错误处理
- [ ] 响应式设计调整

## 🔧 代码模板

### 1. 后端数据模型模板

```python
# backend/models/models.py 中添加

class Tag(Base):
    __tablename__ = "tags"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(50), nullable=False)
    color = Column(String(7), default="#007bff")
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # 关系
    user = relationship("User", back_populates="tags")
    
    # 索引
    __table_args__ = (
        Index('idx_tag_user_name', 'user_id', 'name', unique=True),
    )

# 关联表
transaction_tags = Table(
    'transaction_tags',
    Base.metadata,
    Column('transaction_id', Integer, ForeignKey('transactions.id'), primary_key=True),
    Column('tag_id', Integer, ForeignKey('tags.id'), primary_key=True)
)

# 更新 Transaction 模型
class Transaction(Base):
    # ... 现有字段 ...
    
    # 添加标签关系
    tags = relationship("Tag", secondary=transaction_tags, back_populates="transactions")

# 更新 Tag 模型
class Tag(Base):
    # ... 现有字段 ...
    
    # 添加交易关系
    transactions = relationship("Transaction", secondary=transaction_tags, back_populates="tags")
```

### 2. API 模式模板

```python
# backend/schemas/schemas.py 中添加

class TagBase(BaseModel):
    name: str
    color: Optional[str] = "#007bff"

class TagCreate(TagBase):
    pass

class TagUpdate(BaseModel):
    name: Optional[str] = None
    color: Optional[str] = None

class Tag(TagBase):
    id: int
    user_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class TransactionTagsUpdate(BaseModel):
    tag_ids: List[int]

# 更新现有的 Transaction 模式
class Transaction(TransactionBase):
    id: int
    user_id: int
    created_at: datetime
    tags: List[Tag] = []
    
    class Config:
        from_attributes = True
```

### 3. CRUD 操作模板

```python
# backend/crud/crud.py 中添加

def create_tag(db: Session, tag: TagCreate, user_id: int):
    # 检查标签名是否已存在
    existing_tag = db.query(Tag).filter(
        Tag.user_id == user_id, 
        Tag.name == tag.name
    ).first()
    if existing_tag:
        raise HTTPException(status_code=400, detail="标签名已存在")
    
    db_tag = Tag(**tag.dict(), user_id=user_id)
    db.add(db_tag)
    db.commit()
    db.refresh(db_tag)
    return db_tag

def get_tags(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return db.query(Tag).filter(Tag.user_id == user_id).offset(skip).limit(limit).all()

def get_tag(db: Session, tag_id: int, user_id: int):
    return db.query(Tag).filter(Tag.id == tag_id, Tag.user_id == user_id).first()

def update_tag(db: Session, tag_id: int, tag_update: TagUpdate, user_id: int):
    db_tag = get_tag(db, tag_id, user_id)
    if not db_tag:
        return None
    
    update_data = tag_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_tag, field, value)
    
    db.commit()
    db.refresh(db_tag)
    return db_tag

def delete_tag(db: Session, tag_id: int, user_id: int):
    db_tag = get_tag(db, tag_id, user_id)
    if db_tag:
        db.delete(db_tag)
        db.commit()
    return db_tag

def update_transaction_tags(db: Session, transaction_id: int, tag_ids: List[int], user_id: int):
    # 验证交易属于当前用户
    transaction = db.query(Transaction).filter(
        Transaction.id == transaction_id, 
        Transaction.user_id == user_id
    ).first()
    if not transaction:
        return None
    
    # 验证标签属于当前用户
    tags = db.query(Tag).filter(
        Tag.id.in_(tag_ids), 
        Tag.user_id == user_id
    ).all()
    
    # 更新交易的标签
    transaction.tags = tags
    db.commit()
    db.refresh(transaction)
    return transaction
```

### 4. API 路由模板

```python
# backend/api/tags.py (新文件)

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from ..database.database import get_db
from ..auth.auth import get_current_user
from ..schemas import schemas
from ..crud import crud
from ..models.models import User

router = APIRouter(prefix="/tags", tags=["tags"])

@router.post("/", response_model=schemas.Tag)
def create_tag(
    tag: schemas.TagCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """创建新标签"""
    return crud.create_tag(db=db, tag=tag, user_id=current_user.id)

@router.get("/", response_model=List[schemas.Tag])
def read_tags(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取用户的所有标签"""
    return crud.get_tags(db, user_id=current_user.id, skip=skip, limit=limit)

@router.get("/{tag_id}", response_model=schemas.Tag)
def read_tag(
    tag_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取特定标签"""
    tag = crud.get_tag(db, tag_id=tag_id, user_id=current_user.id)
    if tag is None:
        raise HTTPException(status_code=404, detail="标签不存在")
    return tag

@router.put("/{tag_id}", response_model=schemas.Tag)
def update_tag(
    tag_id: int,
    tag_update: schemas.TagUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """更新标签"""
    tag = crud.update_tag(db, tag_id=tag_id, tag_update=tag_update, user_id=current_user.id)
    if tag is None:
        raise HTTPException(status_code=404, detail="标签不存在")
    return tag

@router.delete("/{tag_id}")
def delete_tag(
    tag_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """删除标签"""
    tag = crud.delete_tag(db, tag_id=tag_id, user_id=current_user.id)
    if tag is None:
        raise HTTPException(status_code=404, detail="标签不存在")
    return {"message": "标签删除成功"}

@router.put("/transactions/{transaction_id}/tags", response_model=schemas.Transaction)
def update_transaction_tags(
    transaction_id: int,
    tags_update: schemas.TransactionTagsUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """更新交易的标签"""
    transaction = crud.update_transaction_tags(
        db, transaction_id=transaction_id, 
        tag_ids=tags_update.tag_ids, 
        user_id=current_user.id
    )
    if transaction is None:
        raise HTTPException(status_code=404, detail="交易不存在")
    return transaction
```

### 5. 前端组件模板

```vue
<!-- frontend/src/components/TagSelector.vue -->
<template>
  <div class="tag-selector">
    <el-select
      v-model="selectedTagIds"
      multiple
      filterable
      placeholder="选择标签"
      @change="handleTagChange"
      style="width: 100%"
    >
      <el-option
        v-for="tag in tags"
        :key="tag.id"
        :label="tag.name"
        :value="tag.id"
      >
        <span class="tag-option">
          <span 
            class="tag-color" 
            :style="{ backgroundColor: tag.color }"
          ></span>
          {{ tag.name }}
        </span>
      </el-option>
    </el-select>
    
    <!-- 已选标签显示 -->
    <div class="selected-tags" v-if="selectedTags.length">
      <el-tag
        v-for="tag in selectedTags"
        :key="tag.id"
        :color="tag.color"
        closable
        @close="removeTag(tag.id)"
        style="margin: 2px"
      >
        {{ tag.name }}
      </el-tag>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { tagApi } from '@/api/tags'

const props = defineProps({
  modelValue: {
    type: Array,
    default: () => []
  }
})

const emit = defineEmits(['update:modelValue'])

const tags = ref([])
const selectedTagIds = ref([])

const selectedTags = computed(() => {
  return tags.value.filter(tag => selectedTagIds.value.includes(tag.id))
})

const loadTags = async () => {
  try {
    const response = await tagApi.getTags()
    tags.value = response.data
  } catch (error) {
    ElMessage.error('加载标签失败')
  }
}

const handleTagChange = () => {
  emit('update:modelValue', selectedTagIds.value)
}

const removeTag = (tagId) => {
  selectedTagIds.value = selectedTagIds.value.filter(id => id !== tagId)
  handleTagChange()
}

onMounted(() => {
  loadTags()
  selectedTagIds.value = props.modelValue
})
</script>

<style scoped>
.tag-option {
  display: flex;
  align-items: center;
}

.tag-color {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  margin-right: 8px;
}

.selected-tags {
  margin-top: 8px;
}
</style>
```

## 🧪 测试模板

### API 测试
```python
# backend/tests/test_tags.py

def test_create_tag(client, auth_headers):
    response = client.post(
        "/tags/",
        json={"name": "测试标签", "color": "#ff0000"},
        headers=auth_headers
    )
    assert response.status_code == 200
    assert response.json()["name"] == "测试标签"

def test_get_tags(client, auth_headers):
    response = client.get("/tags/", headers=auth_headers)
    assert response.status_code == 200
    assert isinstance(response.json(), list)
```

## 📝 开发注意事项

1. **数据库迁移**: 添加新模型后需要重启应用让 SQLAlchemy 创建表
2. **权限验证**: 确保用户只能操作自己的标签
3. **性能优化**: 使用适当的数据库索引
4. **用户体验**: 添加加载状态和错误处理
5. **测试覆盖**: 编写充分的单元测试和集成测试

## 🎯 完成验收标准

- [ ] 所有 API 端点正常工作
- [ ] 前端界面功能完整
- [ ] 数据验证和错误处理完善
- [ ] 用户权限验证正确
- [ ] 性能表现良好
- [ ] 代码质量符合规范
