<template>
  <div class="dashboard">
    <h1>仪表盘</h1>
    
    <div class="welcome-section">
      <h2>欢迎回来，{{ user?.username }}！</h2>
      <p>这里是您的财务概览</p>
    </div>
    
    <div class="stats-grid">
      <div class="stat-card">
        <h3>总收入</h3>
        <div class="stat-value income">¥ {{ totalIncome.toFixed(2) }}</div>
      </div>
      
      <div class="stat-card">
        <h3>总支出</h3>
        <div class="stat-value expense">¥ {{ totalExpense.toFixed(2) }}</div>
      </div>
      
      <div class="stat-card">
        <h3>净收入</h3>
        <div class="stat-value" :class="netIncome >= 0 ? 'income' : 'expense'">
          ¥ {{ netIncome.toFixed(2) }}
        </div>
      </div>
      
      <div class="stat-card">
        <h3>账户数量</h3>
        <div class="stat-value">{{ accountCount }}</div>
      </div>
    </div>
    
    <div class="quick-actions">
      <h3>快速操作</h3>
      <div class="action-buttons">
        <router-link to="/transactions" class="action-btn">
          <span class="icon">💰</span>
          <span>记录交易</span>
        </router-link>
        
        <router-link to="/accounts" class="action-btn">
          <span class="icon">🏦</span>
          <span>管理账户</span>
        </router-link>
        
        <router-link to="/projects" class="action-btn">
          <span class="icon">📊</span>
          <span>项目管理</span>
        </router-link>
      </div>
    </div>
    
    <div class="recent-transactions">
      <h3>最近交易</h3>
      <div v-if="recentTransactions.length === 0" class="no-data">
        暂无交易记录
      </div>
      <div v-else class="transaction-list">
        <div 
          v-for="transaction in recentTransactions" 
          :key="transaction.id"
          class="transaction-item"
        >
          <div class="transaction-info">
            <div class="transaction-title">{{ transaction.title || '无标题' }}</div>
            <div class="transaction-date">{{ formatDate(transaction.transaction_date) }}</div>
          </div>
          <div 
            class="transaction-amount"
            :class="transaction.type"
          >
            {{ transaction.type === 'income' ? '+' : '-' }}¥{{ transaction.amount }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '../stores/auth'
import api from '../api/index'

export default {
  name: 'Dashboard',
  setup() {
    const authStore = useAuthStore()
    const user = computed(() => authStore.user)
    
    const transactions = ref([])
    const accounts = ref([])
    
    const totalIncome = computed(() => {
      return transactions.value
        .filter(t => t.type === 'income')
        .reduce((sum, t) => sum + parseFloat(t.amount), 0)
    })
    
    const totalExpense = computed(() => {
      return transactions.value
        .filter(t => t.type === 'expense')
        .reduce((sum, t) => sum + parseFloat(t.amount), 0)
    })
    
    const netIncome = computed(() => totalIncome.value - totalExpense.value)
    
    const accountCount = computed(() => accounts.value.length)
    
    const recentTransactions = computed(() => {
      return transactions.value
        .sort((a, b) => new Date(b.transaction_date) - new Date(a.transaction_date))
        .slice(0, 5)
    })
    
    const formatDate = (dateString) => {
      return new Date(dateString).toLocaleDateString('zh-CN')
    }
    
    const fetchData = async () => {
      try {
        const [transactionsRes, accountsRes] = await Promise.all([
          api.get('/transactions/'),
          api.get('/accounts/')
        ])
        
        transactions.value = transactionsRes.data
        accounts.value = accountsRes.data
      } catch (error) {
        console.error('Failed to fetch dashboard data:', error)
      }
    }
    
    onMounted(() => {
      fetchData()
    })
    
    return {
      user,
      totalIncome,
      totalExpense,
      netIncome,
      accountCount,
      recentTransactions,
      formatDate
    }
  }
}
</script>

<style scoped>
.dashboard {
  max-width: 1200px;
  margin: 0 auto;
}

.dashboard h1 {
  color: #2c3e50;
  margin-bottom: 2rem;
}

.welcome-section {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  margin-bottom: 2rem;
}

.welcome-section h2 {
  color: #2c3e50;
  margin-bottom: 0.5rem;
}

.welcome-section p {
  color: #7f8c8d;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}

.stat-card {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  text-align: center;
}

.stat-card h3 {
  color: #7f8c8d;
  margin-bottom: 1rem;
  font-size: 0.9rem;
  text-transform: uppercase;
}

.stat-value {
  font-size: 2rem;
  font-weight: bold;
  color: #2c3e50;
}

.stat-value.income {
  color: #27ae60;
}

.stat-value.expense {
  color: #e74c3c;
}

.quick-actions {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  margin-bottom: 2rem;
}

.quick-actions h3 {
  color: #2c3e50;
  margin-bottom: 1rem;
}

.action-buttons {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
}

.action-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 1.5rem;
  background: #f8f9fa;
  border-radius: 8px;
  text-decoration: none;
  color: #2c3e50;
  transition: all 0.2s;
}

.action-btn:hover {
  background: #3498db;
  color: white;
  transform: translateY(-2px);
}

.action-btn .icon {
  font-size: 2rem;
  margin-bottom: 0.5rem;
}

.recent-transactions {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.recent-transactions h3 {
  color: #2c3e50;
  margin-bottom: 1rem;
}

.no-data {
  text-align: center;
  color: #7f8c8d;
  padding: 2rem;
}

.transaction-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.transaction-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 4px;
}

.transaction-info {
  flex: 1;
}

.transaction-title {
  font-weight: 500;
  color: #2c3e50;
}

.transaction-date {
  font-size: 0.9rem;
  color: #7f8c8d;
}

.transaction-amount {
  font-weight: bold;
  font-size: 1.1rem;
}

.transaction-amount.income {
  color: #27ae60;
}

.transaction-amount.expense {
  color: #e74c3c;
}
</style>
