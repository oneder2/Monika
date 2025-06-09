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
    const showAddModal = ref(false)
    const showEditModal = ref(false)
    const loading = ref(false)
    const editingId = ref(null)
    
    const form = ref({
      title: '',
      type: '',
      amount: '',
      account_id: '',
      transaction_date: '',
      notes: ''
    })
    
    const resetForm = () => {
      form.value = {
        title: '',
        type: '',
        amount: '',
        account_id: '',
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
    
    const fetchTransactions = async () => {
      try {
        const response = await api.get('/transactions/')
        transactions.value = response.data
      } catch (error) {
        console.error('Failed to fetch transactions:', error)
      }
    }

    const fetchAccounts = async () => {
      try {
        const response = await api.get('/accounts/')
        accounts.value = response.data
      } catch (error) {
        console.error('Failed to fetch accounts:', error)
      }
    }
    
    const saveTransaction = async () => {
      loading.value = true
      
      try {
        const data = {
          ...form.value,
          amount: parseFloat(form.value.amount),
          currency: 'CNY'
        }
        
        if (showEditModal.value) {
          await api.put(`/transactions/${editingId.value}/`, data)
        } else {
          await api.post('/transactions/', data)
        }
        
        await fetchTransactions()
        closeModal()
      } catch (error) {
        console.error('Failed to save transaction:', error)
        alert('保存失败，请重试')
      }
      
      loading.value = false
    }
    
    const editTransaction = (transaction) => {
      form.value = {
        title: transaction.title || '',
        type: transaction.type,
        amount: transaction.amount,
        account_id: transaction.account_id,
        transaction_date: new Date(transaction.transaction_date).toISOString().slice(0, 16),
        notes: transaction.notes || ''
      }
      editingId.value = transaction.id
      showEditModal.value = true
    }
    
    const deleteTransaction = async (id) => {
      if (!confirm('确定要删除这笔交易吗？')) return
      
      try {
        await api.delete(`/transactions/${id}/`)
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
      resetForm()
    })
    
    return {
      transactions,
      accounts,
      showAddModal,
      showEditModal,
      loading,
      form,
      formatDate,
      getAccountName,
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

.transactions-list {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  overflow: hidden;
}

.no-data {
  text-align: center;
  padding: 3rem;
  color: #7f8c8d;
}

.transaction-table {
  width: 100%;
}

.table-header {
  display: grid;
  grid-template-columns: 150px 1fr 80px 120px 150px 120px;
  gap: 1rem;
  padding: 1rem;
  background: #f8f9fa;
  font-weight: bold;
  color: #2c3e50;
}

.table-row {
  display: grid;
  grid-template-columns: 150px 1fr 80px 120px 150px 120px;
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
