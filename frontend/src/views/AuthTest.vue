<template>
  <div class="auth-test">
    <h1>认证状态测试</h1>
    
    <div class="status-section">
      <h3>当前认证状态</h3>
      <div class="status-item">
        <strong>是否已认证:</strong> {{ authStore.isAuthenticated ? '是' : '否' }}
      </div>
      <div class="status-item">
        <strong>Token:</strong> {{ authStore.token ? authStore.token.substring(0, 20) + '...' : '无' }}
      </div>
      <div class="status-item">
        <strong>用户信息:</strong> {{ authStore.user ? JSON.stringify(authStore.user) : '无' }}
      </div>
    </div>
    
    <div class="test-section">
      <h3>API测试</h3>
      <div class="test-buttons">
        <button @click="testUserInfo" :disabled="loading">测试获取用户信息</button>
        <button @click="testProjects" :disabled="loading">测试获取项目列表</button>
        <button @click="testAccounts" :disabled="loading">测试获取账户列表</button>
        <button @click="testTransactions" :disabled="loading">测试获取交易记录</button>
        <button @click="testCreateTransaction" :disabled="loading">测试交易CRUD</button>
        <button @click="validateToken" :disabled="loading">验证Token</button>
      </div>
    </div>
    
    <div class="results-section">
      <h3>测试结果</h3>
      <div class="results" v-if="results.length > 0">
        <div v-for="(result, index) in results" :key="index" class="result-item" :class="result.success ? 'success' : 'error'">
          <strong>{{ result.test }}:</strong> {{ result.message }}
        </div>
      </div>
      <div v-else class="no-results">
        暂无测试结果
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'
import { useAuthStore } from '../stores/auth'
import api from '../api/index'

export default {
  name: 'AuthTest',
  setup() {
    const authStore = useAuthStore()
    const loading = ref(false)
    const results = ref([])
    
    const addResult = (test, success, message) => {
      results.value.unshift({
        test,
        success,
        message,
        timestamp: new Date().toLocaleTimeString()
      })
    }
    
    const testUserInfo = async () => {
      loading.value = true
      try {
        const response = await api.get('/users/me')
        addResult('获取用户信息', true, `成功: ${JSON.stringify(response.data)}`)
      } catch (error) {
        addResult('获取用户信息', false, `失败: ${error.response?.data?.detail || error.message}`)
      }
      loading.value = false
    }

    const testProjects = async () => {
      loading.value = true
      try {
        const response = await api.get('/projects')
        addResult('获取项目列表', true, `成功: 找到 ${response.data.length} 个项目`)
      } catch (error) {
        addResult('获取项目列表', false, `失败: ${error.response?.data?.detail || error.message}`)
      }
      loading.value = false
    }

    const testAccounts = async () => {
      loading.value = true
      try {
        const response = await api.get('/accounts')
        addResult('获取账户列表', true, `成功: 找到 ${response.data.length} 个账户`)
      } catch (error) {
        addResult('获取账户列表', false, `失败: ${error.response?.data?.detail || error.message}`)
      }
      loading.value = false
    }

    const testTransactions = async () => {
      loading.value = true
      try {
        const response = await api.get('/transactions')
        addResult('获取交易记录', true, `成功: 找到 ${response.data.length} 条记录`)
      } catch (error) {
        addResult('获取交易记录', false, `失败: ${error.response?.data?.detail || error.message}`)
      }
      loading.value = false
    }

    const testCreateTransaction = async () => {
      loading.value = true
      try {
        // 先获取账户
        const accountsRes = await api.get('/accounts')
        if (accountsRes.data.length === 0) {
          addResult('创建交易记录', false, '没有可用账户')
          loading.value = false
          return
        }

        const newTransaction = {
          account_id: accountsRes.data[0].id,
          project_id: null,
          category_id: null,
          type: "expense",
          title: "前端测试交易",
          amount: 99.99,
          currency: "CNY",
          transaction_date: new Date().toISOString(),
          notes: "这是前端测试创建的交易记录"
        }

        const response = await api.post('/transactions', newTransaction)
        addResult('创建交易记录', true, `成功: 创建了交易 ID ${response.data.id}`)

        // 测试更新
        const updateData = {
          title: "更新后的前端测试交易",
          amount: 199.99
        }

        const updateRes = await api.put(`/transactions/${response.data.id}`, updateData)
        addResult('更新交易记录', true, `成功: 更新了交易 "${updateRes.data.title}"`)

        // 测试删除
        await api.delete(`/transactions/${response.data.id}`)
        addResult('删除交易记录', true, '成功: 删除了测试交易')

      } catch (error) {
        addResult('交易CRUD测试', false, `失败: ${error.response?.data?.detail || error.message}`)
        console.error('Transaction CRUD test error:', error)
      }
      loading.value = false
    }
    
    const validateToken = async () => {
      loading.value = true
      try {
        const response = await api.get('/auth/verify')
        addResult('验证Token', true, `成功: ${JSON.stringify(response.data)}`)
      } catch (error) {
        addResult('验证Token', false, `失败: ${error.response?.data?.detail || error.message}`)
      }
      loading.value = false
    }
    
    return {
      authStore,
      loading,
      results,
      testUserInfo,
      testProjects,
      testAccounts,
      testTransactions,
      testCreateTransaction,
      validateToken
    }
  }
}
</script>

<style scoped>
.auth-test {
  max-width: 800px;
  margin: 0 auto;
  padding: 2rem;
}

.status-section, .test-section, .results-section {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  margin-bottom: 2rem;
}

.status-item {
  margin-bottom: 1rem;
  padding: 0.5rem;
  background: #f8f9fa;
  border-radius: 4px;
}

.test-buttons {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
}

.test-buttons button {
  padding: 0.75rem 1rem;
  background: #3498db;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.test-buttons button:hover:not(:disabled) {
  background: #2980b9;
}

.test-buttons button:disabled {
  background: #bdc3c7;
  cursor: not-allowed;
}

.results {
  max-height: 400px;
  overflow-y: auto;
}

.result-item {
  padding: 1rem;
  margin-bottom: 0.5rem;
  border-radius: 4px;
  border-left: 4px solid;
}

.result-item.success {
  background: #d4edda;
  border-color: #27ae60;
  color: #155724;
}

.result-item.error {
  background: #f8d7da;
  border-color: #e74c3c;
  color: #721c24;
}

.no-results {
  text-align: center;
  color: #7f8c8d;
  padding: 2rem;
}
</style>
