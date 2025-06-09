#!/usr/bin/env python3
"""
测试认证修复的脚本
"""
import requests
import json

# API基础URL
BASE_URL = "http://127.0.0.1:8000"

def test_login():
    """测试登录功能"""
    print("=== 测试登录功能 ===")
    
    login_data = {
        "username": "testuser",
        "password": "testpass123"
    }
    
    response = requests.post(f"{BASE_URL}/auth/token", data=login_data)
    print(f"登录响应状态: {response.status_code}")
    
    if response.status_code == 200:
        token_data = response.json()
        token = token_data["access_token"]
        print(f"登录成功，获得token: {token[:20]}...")
        return {"Authorization": f"Bearer {token}"}
    else:
        print(f"登录失败: {response.text}")
        return None

def test_token_verification(headers):
    """测试token验证"""
    print("\n=== 测试token验证 ===")
    
    response = requests.get(f"{BASE_URL}/auth/verify/", headers=headers)
    print(f"验证响应状态: {response.status_code}")
    
    if response.status_code == 200:
        print(f"Token验证成功: {response.json()}")
        return True
    else:
        print(f"Token验证失败: {response.text}")
        return False

def test_user_info(headers):
    """测试获取用户信息"""
    print("\n=== 测试获取用户信息 ===")
    
    response = requests.get(f"{BASE_URL}/users/me/", headers=headers)
    print(f"用户信息响应状态: {response.status_code}")
    
    if response.status_code == 200:
        user_info = response.json()
        print(f"用户信息: {user_info}")
        return True
    else:
        print(f"获取用户信息失败: {response.text}")
        return False

def test_projects_crud(headers):
    """测试项目CRUD功能"""
    print("\n=== 测试项目CRUD功能 ===")

    # 获取项目列表
    response = requests.get(f"{BASE_URL}/projects/", headers=headers)
    print(f"获取项目列表状态: {response.status_code}")

    if response.status_code == 200:
        projects = response.json()
        print(f"现有项目数量: {len(projects)}")

        # 创建新项目
        new_project = {
            "name": "测试项目CRUD",
            "description": "这是一个测试项目CRUD功能",
            "start_date": "2025-06-01",
            "end_date": "2025-12-31"
        }

        response = requests.post(f"{BASE_URL}/projects/", json=new_project, headers=headers)
        print(f"创建项目状态: {response.status_code}")

        if response.status_code == 200:
            created_project = response.json()
            print(f"创建项目成功: {created_project['name']} (ID: {created_project['id']})")

            # 测试更新项目
            update_data = {
                "name": "更新后的测试项目",
                "description": "更新后的描述"
            }

            response = requests.put(f"{BASE_URL}/projects/{created_project['id']}/", json=update_data, headers=headers)
            print(f"更新项目状态: {response.status_code}")

            if response.status_code == 200:
                updated_project = response.json()
                print(f"更新项目成功: {updated_project['name']}")

                # 测试删除项目
                response = requests.delete(f"{BASE_URL}/projects/{created_project['id']}/", headers=headers)
                print(f"删除项目状态: {response.status_code}")

                if response.status_code == 200:
                    print("删除项目成功")
                    return True
                else:
                    print(f"删除项目失败: {response.text}")
                    return False
            else:
                print(f"更新项目失败: {response.text}")
                return False
        else:
            print(f"创建项目失败: {response.text}")
            print(f"响应内容: {response.text}")
            return False
    else:
        print(f"获取项目列表失败: {response.text}")
        return False

def test_accounts_crud(headers):
    """测试账户CRUD功能"""
    print("\n=== 测试账户CRUD功能 ===")
    
    # 获取账户列表
    response = requests.get(f"{BASE_URL}/accounts/", headers=headers)
    print(f"获取账户列表状态: {response.status_code}")
    
    if response.status_code == 200:
        accounts = response.json()
        print(f"现有账户数量: {len(accounts)}")
        return True
    else:
        print(f"获取账户列表失败: {response.text}")
        return False

def test_transactions_crud(headers):
    """测试交易记录CRUD功能"""
    print("\n=== 测试交易记录CRUD功能 ===")

    # 先获取账户列表
    accounts_response = requests.get(f"{BASE_URL}/accounts/", headers=headers)
    if accounts_response.status_code != 200:
        print("无法获取账户列表，跳过交易测试")
        return False

    accounts = accounts_response.json()
    if not accounts:
        print("没有可用账户，跳过交易测试")
        return False

    account_id = accounts[0]["id"]

    # 获取交易记录列表
    response = requests.get(f"{BASE_URL}/transactions/", headers=headers)
    print(f"获取交易记录状态: {response.status_code}")

    if response.status_code == 200:
        transactions = response.json()
        print(f"现有交易记录数量: {len(transactions)}")

        # 创建新交易记录
        new_transaction = {
            "account_id": account_id,
            "project_id": None,
            "category_id": None,
            "type": "expense",
            "title": "测试交易",
            "amount": 100.50,
            "currency": "CNY",
            "transaction_date": "2025-06-08T12:00:00",
            "notes": "这是一个测试交易记录"
        }

        response = requests.post(f"{BASE_URL}/transactions/", json=new_transaction, headers=headers)
        print(f"创建交易记录状态: {response.status_code}")

        if response.status_code == 200:
            created_transaction = response.json()
            print(f"创建交易记录成功: {created_transaction['title']} (ID: {created_transaction['id']})")

            # 测试更新交易记录
            update_data = {
                "title": "更新后的测试交易",
                "amount": 200.75,
                "notes": "更新后的备注"
            }

            response = requests.put(f"{BASE_URL}/transactions/{created_transaction['id']}/", json=update_data, headers=headers)
            print(f"更新交易记录状态: {response.status_code}")

            if response.status_code == 200:
                updated_transaction = response.json()
                print(f"更新交易记录成功: {updated_transaction['title']}")

                # 测试删除交易记录
                response = requests.delete(f"{BASE_URL}/transactions/{created_transaction['id']}/", headers=headers)
                print(f"删除交易记录状态: {response.status_code}")

                if response.status_code == 200:
                    print("删除交易记录成功")
                    return True
                else:
                    print(f"删除交易记录失败: {response.text}")
                    return False
            else:
                print(f"更新交易记录失败: {response.text}")
                print(f"响应内容: {response.text}")
                return False
        else:
            print(f"创建交易记录失败: {response.text}")
            print(f"响应内容: {response.text}")
            return False
    else:
        print(f"获取交易记录失败: {response.text}")
        return False

def main():
    """主函数"""
    print("开始测试认证和CRUD功能...")
    
    # 测试登录
    headers = test_login()
    if not headers:
        print("登录失败，无法继续测试")
        return
    
    # 测试token验证
    if not test_token_verification(headers):
        print("Token验证失败")
        return
    
    # 测试获取用户信息
    if not test_user_info(headers):
        print("获取用户信息失败")
        return
    
    # 测试各种CRUD功能
    test_projects_crud(headers)
    test_accounts_crud(headers)
    test_transactions_crud(headers)
    
    print("\n=== 测试完成 ===")
    print("如果所有测试都通过，说明认证和CRUD功能已修复")

if __name__ == "__main__":
    main()
