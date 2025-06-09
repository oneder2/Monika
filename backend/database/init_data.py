"""
初始化数据库默认数据
"""
from sqlalchemy.orm import Session
from backend.database.database import SessionLocal, engine
from backend.models.models import Category, Base

# 创建所有表
Base.metadata.create_all(bind=engine)

def init_default_categories():
    """初始化默认分类"""
    db = SessionLocal()
    
    # 检查是否已有默认分类
    existing_categories = db.query(Category).filter(Category.user_id.is_(None)).first()
    if existing_categories:
        print("默认分类已存在，跳过初始化")
        db.close()
        return
    
    # 支出分类
    expense_categories = [
        {"name": "餐饮", "type": "expense", "icon_name": "restaurant"},
        {"name": "交通", "type": "expense", "icon_name": "directions_car"},
        {"name": "购物", "type": "expense", "icon_name": "shopping_cart"},
        {"name": "娱乐", "type": "expense", "icon_name": "movie"},
        {"name": "医疗", "type": "expense", "icon_name": "local_hospital"},
        {"name": "教育", "type": "expense", "icon_name": "school"},
        {"name": "住房", "type": "expense", "icon_name": "home"},
        {"name": "通讯", "type": "expense", "icon_name": "phone"},
        {"name": "其他支出", "type": "expense", "icon_name": "more_horiz"},
    ]
    
    # 收入分类
    income_categories = [
        {"name": "工资", "type": "income", "icon_name": "work"},
        {"name": "奖金", "type": "income", "icon_name": "card_giftcard"},
        {"name": "投资收益", "type": "income", "icon_name": "trending_up"},
        {"name": "兼职", "type": "income", "icon_name": "business_center"},
        {"name": "其他收入", "type": "income", "icon_name": "more_horiz"},
    ]
    
    all_categories = expense_categories + income_categories
    
    for cat_data in all_categories:
        category = Category(
            user_id=None,  # 系统默认分类
            **cat_data
        )
        db.add(category)
    
    db.commit()
    print(f"成功初始化 {len(all_categories)} 个默认分类")
    db.close()

if __name__ == "__main__":
    init_default_categories()
