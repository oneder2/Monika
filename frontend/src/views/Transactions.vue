<template>
  <div class="transactions">
    <div class="page-header">
      <h1>交易记录</h1>
      <button @click="showAddModal = true" class="add-btn">
        + 添加交易
      </button>
    </div>
    
    <div class="transactions-list">
      <div v-if="transactions.length === 0" class="no-data">
        暂无交易记录，点击上方按钮添加第一笔交易
      </div>
      
      <div v-else class="transaction-table">
        <div class="table-header">
          <div>日期</div>
          <div>标题</div>
          <div>类型</div>
          <div>金额</div>
          <div>账户</div>
          <div>项目</div>
          <div>操作</div>
        </div>
        
        <div 
          v-for="transaction in transactions" 
          :key="transaction.id"
          class="table-row"
        >
          <div>{{ formatDate(transaction.transaction_date) }}</div>
          <div>{{ transaction.title || '无标题' }}</div>
          <div>
            <span
              class="type-badge"
              :class="transaction.type"
            >
              {{ transaction.type === 'income' ? '收入' : '支出' }}
            </span>
          </div>
          <div
            class="amount"
            :class="transaction.type"
          >
            {{ transaction.type === 'income' ? '+' : '-' }}¥{{ transaction.amount }}
          </div>
          <div>{{ getAccountName(transaction.account_id) }}</div>
          <div>{{ getProjectName(transaction.project_id) }}</div>
          <div class="actions">
            <button @click="editTransaction(transaction)" class="edit-btn">编辑</button>
            <button @click="deleteTransaction(transaction.id)" class="delete-btn">删除</button>
          </div>
        </div>
      </div>
    </div>
    
    <!-- 添加/编辑交易模态框 -->
    <div v-if="showAddModal || showEditModal" class="modal-overlay" @click="closeModal">
      <div class="modal" @click.stop>
        <h3>{{ showEditModal ? '编辑交易' : '添加交易' }}</h3>
        
        <form @submit.prevent="saveTransaction">
          <div class="form-group">
            <label>标题</label>
            <input v-model="form.title" type="text" placeholder="交易标题" />
          </div>
          
          <div class="form-group">
            <label>类型</label>
            <select v-model="form.type" required>
              <option value="">请选择类型</option>
              <option value="income">收入</option>
              <option value="expense">支出</option>
            </select>
          </div>
          
          <div class="form-group">
            <label>金额</label>
            <input v-model="form.amount" type="number" step="0.01" required placeholder="0.00" />
          </div>
          
          <div class="form-group">
            <label>账户</label>
            <select v-model="form.account_id" required>
              <option value="">请选择账户</option>
              <option v-for="account in accounts" :key="account.id" :value="account.id">
                {{ account.name }}
              </option>
            </select>
          </div>

          <div class="form-group">
            <label>项目</label>
            <select v-model="form.project_id">
              <option value="">请选择项目（可选）</option>
              <option v-for="project in projects" :key="project.id" :value="project.id">
                {{ project.name }}
              </option>
            </select>
          </div>

          <div class="form-group">
            <label>交易日期</label>
            <input v-model="form.transaction_date" type="datetime-local" required />
          </div>
          
          <div class="form-group">
            <label>备注</label>
            <textarea v-model="form.notes" placeholder="备注信息"></textarea>
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
import { ref, onMounted, computed } from 'vue'
import api from '../api/index'

export default {
  name: 'Transactions',
  setup() {
    const transactions = ref([])
    const accounts = ref([])
    const projects = ref([])
    const showAddModal = ref(false)
    const showEditModal = ref(false)
    const loading = ref(false)
    const editingId = ref(null)
    
    const form = ref({
      title: '',
      type: '',
      amount: '',
      account_id: '',
      project_id: '',
      transaction_date: '',
      notes: ''
    })
    
    const resetForm = () => {
      form.value = {
        title: '',
        type: '',
        amount: '',
        account_id: '',
        project_id: '',
        transaction_date: new Date().toISOString().slice(0, 16),
        notes: ''
      }
    }
    
    const formatDate = (dateString) => {
      return new Date(dateString).toLocaleString('zh-CN')
    }
    
    const getAccountName = (accountId) => {
      const account = accounts.value.find(a => a.id === accountId)
      return account ? account.name : '未知账户'
    }

    const getProjectName = (projectId) => {
      if (!projectId) return '无项目'
      const project = projects.value.find(p => p.id === projectId)
      return project ? project.name : '未知项目'
    }
    
    const fetchTransactions = async () => {
      try {
        const response = await api.get('/transactions')
        transactions.value = response.data
      } catch (error) {
        console.error('Failed to fetch transactions:', error)
      }
    }

    const fetchAccounts = async () => {
      try {
        const response = await api.get('/accounts')
        accounts.value = response.data
      } catch (error) {
        console.error('Failed to fetch accounts:', error)
      }
    }

    const fetchProjects = async () => {
      try {
        const response = await api.get('/projects')
        projects.value = response.data
      } catch (error) {
        console.error('Failed to fetch projects:', error)
      }
    }
    
    const saveTransaction = async () => {
      loading.value = true

      try {
        const data = {
          ...form.value,
          amount: parseFloat(form.value.amount),
          currency: 'CNY',
          project_id: form.value.project_id || null
        }

        console.log('Saving transaction with data:', data)
        console.log('Edit mode:', showEditModal.value, 'ID:', editingId.value)

        let response
        if (showEditModal.value) {
          response = await api.put(`/transactions/${editingId.value}`, data)
          console.log('Update response:', response)
        } else {
          response = await api.post('/transactions', data)
          console.log('Create response:', response)
        }

        await fetchTransactions()
        closeModal()
      } catch (error) {
        console.error('Failed to save transaction:', error)
        console.error('Error details:', {
          status: error.response?.status,
          data: error.response?.data,
          message: error.message
        })

        let errorMessage = '保存失败，请重试'
        if (error.response?.data?.detail) {
          errorMessage = `保存失败: ${error.response.data.detail}`
        } else if (error.response?.status === 401) {
          errorMessage = '认证失败，请重新登录'
        } else if (error.response?.status === 422) {
          errorMessage = '数据格式错误，请检查输入'
        }

        alert(errorMessage)
      }

      loading.value = false
    }
    
    const editTransaction = (transaction) => {
      form.value = {
        title: transaction.title || '',
        type: transaction.type,
        amount: transaction.amount,
        account_id: transaction.account_id,
        project_id: transaction.project_id || '',
        transaction_date: new Date(transaction.transaction_date).toISOString().slice(0, 16),
        notes: transaction.notes || ''
      }
      editingId.value = transaction.id
      showEditModal.value = true
    }
    
    const deleteTransaction = async (id) => {
      if (!confirm('确定要删除这笔交易吗？')) return

      try {
        await api.delete(`/transactions/${id}`)
        await fetchTransactions()
      } catch (error) {
        console.error('Failed to delete transaction:', error)
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
      fetchTransactions()
      fetchAccounts()
      fetchProjects()
      resetForm()
    })
    
    return {
      transactions,
      accounts,
      projects,
      showAddModal,
      showEditModal,
      loading,
      form,
      formatDate,
      getAccountName,
      getProjectName,
      saveTransaction,
      editTransaction,
      deleteTransaction,
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
  margin-bottom: var(--spacing-xl);
  padding: var(--spacing-xl);
  background: var(--bg-primary);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-md);
  border: 1px solid var(--border-color);
}

.page-header h1 {
  color: var(--text-primary);
  font-size: 2.25rem;
  font-weight: 700;
  background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.add-btn {
  background: linear-gradient(135deg, var(--secondary-color) 0%, var(--secondary-hover) 100%);
  color: white;
  border: none;
  padding: var(--spacing-md) var(--spacing-lg);
  border-radius: var(--border-radius-sm);
  cursor: pointer;
  font-size: 1rem;
  font-weight: 500;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
}

.add-btn::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent);
  transition: left 0.5s;
}

.add-btn:hover::before {
  left: 100%;
}

.add-btn:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-lg);
}

.transactions-list {
  background: var(--bg-primary);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-md);
  overflow: hidden;
  border: 1px solid var(--border-color);
}

.no-data {
  text-align: center;
  padding: var(--spacing-2xl);
  color: var(--text-muted);
  font-size: 1.1rem;
}

.transaction-table {
  width: 100%;
}

.table-header {
  display: grid;
  grid-template-columns: 150px 1fr 80px 120px 150px 120px 120px;
  gap: 1rem;
  padding: 1rem;
  background: #f8f9fa;
  font-weight: bold;
  color: #2c3e50;
}

.table-row {
  display: grid;
  grid-template-columns: 150px 1fr 80px 120px 150px 120px 120px;
  gap: 1rem;
  padding: 1rem;
  border-bottom: 1px solid #ecf0f1;
  align-items: center;
}

.table-row:hover {
  background: #f8f9fa;
}

.type-badge {
  padding: 0.25rem 0.5rem;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: bold;
}

.type-badge.income {
  background: #d5f4e6;
  color: #27ae60;
}

.type-badge.expense {
  background: #fadbd8;
  color: #e74c3c;
}

.amount.income {
  color: #27ae60;
  font-weight: bold;
}

.amount.expense {
  color: #e74c3c;
  font-weight: bold;
}

.actions {
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
  max-height: 90vh;
  overflow-y: auto;
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

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

.form-group textarea {
  height: 80px;
  resize: vertical;
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
