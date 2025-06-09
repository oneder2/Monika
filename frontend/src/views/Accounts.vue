<template>
  <div class="accounts">
    <div class="page-header">
      <h1>账户管理</h1>
      <button @click="showAddModal = true" class="add-btn">
        + 添加账户
      </button>
    </div>
    
    <div class="accounts-grid">
      <div v-if="accounts.length === 0" class="no-data">
        暂无账户，点击上方按钮添加第一个账户
      </div>
      
      <div 
        v-for="account in accounts" 
        :key="account.id"
        class="account-card"
      >
        <div class="account-header">
          <h3>{{ account.name }}</h3>
          <div class="account-actions">
            <button @click="editAccount(account)" class="edit-btn">编辑</button>
            <button @click="deleteAccount(account.id)" class="delete-btn">删除</button>
          </div>
        </div>
        
        <div class="account-info">
          <div class="account-type">{{ getAccountTypeLabel(account.type) }}</div>
          <div class="account-balance">
            初始余额: ¥{{ account.initial_balance }}
          </div>
          <div class="account-status">
            <span 
              class="status-badge"
              :class="{ active: account.is_active, inactive: !account.is_active }"
            >
              {{ account.is_active ? '活跃' : '停用' }}
            </span>
          </div>
        </div>
      </div>
    </div>
    
    <!-- 添加/编辑账户模态框 -->
    <div v-if="showAddModal || showEditModal" class="modal-overlay" @click="closeModal">
      <div class="modal" @click.stop>
        <h3>{{ showEditModal ? '编辑账户' : '添加账户' }}</h3>
        
        <form @submit.prevent="saveAccount">
          <div class="form-group">
            <label>账户名称</label>
            <input v-model="form.name" type="text" required placeholder="例如：招商银行储蓄卡" />
          </div>

          <div class="form-group">
            <label>账户类型</label>
            <select v-model="form.type" required>
              <option value="">请选择类型</option>
              <option value="debit_card">储蓄卡</option>
              <option value="credit_card">信用卡</option>
              <option value="cash">现金</option>
              <option value="alipay">支付宝</option>
              <option value="wechat">微信</option>
              <option value="other">其他</option>
            </select>
          </div>

          <div class="form-group">
            <label>初始余额</label>
            <input v-model.number="form.initial_balance" type="number" step="0.01" min="0" placeholder="0.00" />
          </div>
          
          <div class="form-group">
            <label>
              <input v-model="form.is_active" type="checkbox" />
              账户活跃状态
            </label>
          </div>
          
          <div class="modal-actions">
            <button type="button" @click="closeModal" class="cancel-btn">取消</button>
            <button type="submit" :disabled="loading" class="save-btn">
              {{ loading ? '保存中...' : '保存' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import api from '../api/index'

export default {
  name: 'Accounts',
  setup() {
    const accounts = ref([])
    const showAddModal = ref(false)
    const showEditModal = ref(false)
    const loading = ref(false)
    const editingId = ref(null)
    
    const form = ref({
      name: '',
      type: '',
      initial_balance: 0.00,
      is_active: true
    })
    
    const accountTypes = {
      debit_card: '储蓄卡',
      credit_card: '信用卡',
      cash: '现金',
      alipay: '支付宝',
      wechat: '微信',
      other: '其他'
    }
    
    const resetForm = () => {
      form.value = {
        name: '',
        type: '',
        initial_balance: 0.00,
        is_active: true
      }
    }
    
    const getAccountTypeLabel = (type) => {
      return accountTypes[type] || type
    }
    
    const fetchAccounts = async () => {
      try {
        const response = await api.get('/accounts')
        accounts.value = response.data
      } catch (error) {
        console.error('Failed to fetch accounts:', error)
      }
    }
    
    const saveAccount = async () => {
      loading.value = true

      try {
        // 验证必填字段
        if (!form.value.name.trim()) {
          alert('请输入账户名称')
          loading.value = false
          return
        }

        if (!form.value.type) {
          alert('请选择账户类型')
          loading.value = false
          return
        }

        const data = {
          ...form.value,
          name: form.value.name.trim(),
          initial_balance: parseFloat(form.value.initial_balance) || 0.0
        }

        console.log('Sending account data:', data)

        if (showEditModal.value) {
          await api.put(`/accounts/${editingId.value}`, data)
        } else {
          await api.post('/accounts', data)
        }

        await fetchAccounts()
        closeModal()
      } catch (error) {
        console.error('Failed to save account:', error)
        console.error('Error details:', error.response?.data)
        alert('保存失败，请重试')
      }

      loading.value = false
    }
    
    const editAccount = (account) => {
      form.value = {
        name: account.name,
        type: account.type,
        initial_balance: account.initial_balance,
        is_active: account.is_active
      }
      editingId.value = account.id
      showEditModal.value = true
    }
    
    const deleteAccount = async (id) => {
      if (!confirm('确定要删除这个账户吗？')) return

      try {
        await api.delete(`/accounts/${id}`)
        await fetchAccounts()
      } catch (error) {
        console.error('Failed to delete account:', error)
        alert('删除失败，请重试')
      }
    }
    
    const closeModal = () => {
      showAddModal.value = false
      showEditModal.value = false
      editingId.value = null
      resetForm()
    }
    
    onMounted(() => {
      fetchAccounts()
    })
    
    return {
      accounts,
      showAddModal,
      showEditModal,
      loading,
      form,
      getAccountTypeLabel,
      saveAccount,
      editAccount,
      deleteAccount,
      closeModal
    }
  }
}
</script>

<style scoped>
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.page-header h1 {
  color: #2c3e50;
}

.add-btn {
  background: #27ae60;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1rem;
}

.add-btn:hover {
  background: #229954;
}

.accounts-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1.5rem;
}

.no-data {
  grid-column: 1 / -1;
  text-align: center;
  padding: 3rem;
  color: #7f8c8d;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.account-card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  padding: 1.5rem;
  transition: transform 0.2s;
}

.account-card:hover {
  transform: translateY(-2px);
}

.account-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.account-header h3 {
  color: #2c3e50;
  margin: 0;
}

.account-actions {
  display: flex;
  gap: 0.5rem;
}

.edit-btn, .delete-btn {
  padding: 0.25rem 0.5rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.8rem;
}

.edit-btn {
  background: #3498db;
  color: white;
}

.edit-btn:hover {
  background: #2980b9;
}

.delete-btn {
  background: #e74c3c;
  color: white;
}

.delete-btn:hover {
  background: #c0392b;
}

.account-info {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.account-type {
  color: #7f8c8d;
  font-size: 0.9rem;
}

.account-balance {
  color: #2c3e50;
  font-weight: 500;
}

.status-badge {
  padding: 0.25rem 0.5rem;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: bold;
}

.status-badge.active {
  background: #d5f4e6;
  color: #27ae60;
}

.status-badge.inactive {
  background: #fadbd8;
  color: #e74c3c;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  width: 90%;
  max-width: 500px;
}

.modal h3 {
  margin-bottom: 1.5rem;
  color: #2c3e50;
}

.form-group {
  margin-bottom: 1rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  color: #2c3e50;
  font-weight: 500;
}

.form-group input[type="checkbox"] {
  margin-right: 0.5rem;
}

.form-group input,
.form-group select {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

.modal-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 2rem;
}

.cancel-btn, .save-btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1rem;
}

.cancel-btn {
  background: #95a5a6;
  color: white;
}

.cancel-btn:hover {
  background: #7f8c8d;
}

.save-btn {
  background: #27ae60;
  color: white;
}

.save-btn:hover:not(:disabled) {
  background: #229954;
}

.save-btn:disabled {
  background: #bdc3c7;
  cursor: not-allowed;
}
</style>
