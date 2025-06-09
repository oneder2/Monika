<template>
  <div class="dashboard">
    <h1 class="fade-in">仪表盘</h1>

    <div class="welcome-section fade-in">
      <h2>欢迎回来，{{ user?.username }}！</h2>
      <p>这里是您的财务概览</p>
    </div>

    <div class="stats-grid">
      <div class="stat-card fade-in" style="animation-delay: 0.1s">
        <h3>总收入</h3>
        <div class="stat-value income">¥ {{ totalIncome.toFixed(2) }}</div>
      </div>

      <div class="stat-card fade-in" style="animation-delay: 0.2s">
        <h3>总支出</h3>
        <div class="stat-value expense">¥ {{ totalExpense.toFixed(2) }}</div>
      </div>

      <div class="stat-card fade-in" style="animation-delay: 0.3s">
        <h3>净收入</h3>
        <div class="stat-value" :class="netIncome >= 0 ? 'income' : 'expense'">
          ¥ {{ netIncome.toFixed(2) }}
        </div>
      </div>

      <div class="stat-card fade-in" style="animation-delay: 0.4s">
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
    
    <div class="project-summary">
      <h3>项目汇总</h3>
      <div v-if="projectSummaries.length === 0" class="no-data">
        暂无项目数据
      </div>
      <div v-else class="project-list">
        <div
          v-for="project in projectSummaries"
          :key="project.id"
          class="project-summary-item"
        >
          <div class="project-info">
            <div class="project-name">{{ project.name }}</div>
            <div class="project-stats">
              <span class="stat">{{ project.transaction_count }} 笔交易</span>
            </div>
          </div>
          <div class="project-amounts">
            <div class="amount income">收入: ¥{{ project.total_income.toFixed(2) }}</div>
            <div class="amount expense">支出: ¥{{ project.total_expense.toFixed(2) }}</div>
            <div class="amount net" :class="project.net_amount >= 0 ? 'income' : 'expense'">
              净额: ¥{{ project.net_amount.toFixed(2) }}
            </div>
          </div>
        </div>
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
            <div class="transaction-project" v-if="transaction.project_id">
              项目: {{ getProjectName(transaction.project_id) }}
            </div>
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
    const projects = ref([])
    const projectSummaries = ref([])
    
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

    const getProjectName = (projectId) => {
      const project = projects.value.find(p => p.id === projectId)
      return project ? project.name : '未知项目'
    }
    
    const fetchData = async () => {
      try {
        const [transactionsRes, accountsRes, projectsRes] = await Promise.all([
          api.get('/transactions'),
          api.get('/accounts'),
          api.get('/projects')
        ])

        transactions.value = transactionsRes.data
        accounts.value = accountsRes.data
        projects.value = projectsRes.data

        // 获取项目统计信息
        await fetchProjectSummaries()
      } catch (error) {
        console.error('Failed to fetch dashboard data:', error)
      }
    }

    const fetchProjectSummaries = async () => {
      try {
        const summaries = []

        for (const project of projects.value) {
          const statsRes = await api.get(`/projects/${project.id}/stats`)
          summaries.push({
            ...project,
            ...statsRes.data
          })
        }

        // 按净收入排序，收入高的在前
        projectSummaries.value = summaries.sort((a, b) => b.net_amount - a.net_amount)
      } catch (error) {
        console.error('Failed to fetch project summaries:', error)
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
      projectSummaries,
      formatDate,
      getProjectName
    }
  }
}
</script>

<style scoped>
.dashboard {
  max-width: 1400px;
  margin: 0 auto;
}

.dashboard h1 {
  color: var(--text-primary);
  margin-bottom: var(--spacing-xl);
  font-size: 2.5rem;
  font-weight: 700;
  background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.welcome-section {
  background: linear-gradient(135deg, var(--bg-primary) 0%, var(--primary-light) 100%);
  padding: var(--spacing-2xl);
  border-radius: var(--border-radius-lg);
  box-shadow: var(--shadow-lg);
  margin-bottom: var(--spacing-xl);
  text-align: center;
  border: 1px solid var(--border-color);
  position: relative;
  overflow: hidden;
}

.welcome-section::before {
  content: '';
  position: absolute;
  top: -50%;
  left: -50%;
  width: 200%;
  height: 200%;
  background: radial-gradient(circle, rgba(99, 102, 241, 0.1) 0%, transparent 70%);
  animation: float 6s ease-in-out infinite;
}

@keyframes float {
  0%, 100% { transform: translateY(0px) rotate(0deg); }
  50% { transform: translateY(-10px) rotate(180deg); }
}

.welcome-section h2 {
  color: var(--text-primary);
  margin-bottom: var(--spacing-sm);
  font-size: 1.75rem;
  font-weight: 600;
  position: relative;
  z-index: 1;
}

.welcome-section p {
  color: var(--text-secondary);
  font-size: 1.1rem;
  position: relative;
  z-index: 1;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: var(--spacing-lg);
  margin-bottom: var(--spacing-xl);
}

.stat-card {
  background: var(--bg-primary);
  padding: var(--spacing-xl);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-md);
  text-align: center;
  border: 1px solid var(--border-color);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
}

.stat-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  background: linear-gradient(90deg, var(--primary-color), var(--secondary-color));
}

.stat-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-xl);
}

.stat-card h3 {
  color: var(--text-muted);
  margin-bottom: var(--spacing-md);
  font-size: 0.875rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  font-weight: 600;
}

.stat-value {
  font-size: 2.5rem;
  font-weight: 700;
  color: var(--text-primary);
  margin-bottom: var(--spacing-sm);
  background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.stat-value.income {
  background: linear-gradient(135deg, var(--secondary-color) 0%, #34d399 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.stat-value.expense {
  background: linear-gradient(135deg, var(--danger-color) 0%, #f87171 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
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

.project-summary {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  margin-bottom: 2rem;
}

.project-summary h3 {
  color: #2c3e50;
  margin-bottom: 1rem;
}

.project-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.project-summary-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  background: #f8f9fa;
  border-radius: 8px;
  border-left: 4px solid #3498db;
}

.project-info {
  flex: 1;
}

.project-name {
  font-weight: 600;
  color: #2c3e50;
  font-size: 1.1rem;
  margin-bottom: 0.5rem;
}

.project-stats {
  color: #7f8c8d;
  font-size: 0.9rem;
}

.project-amounts {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 0.25rem;
}

.amount {
  font-size: 0.9rem;
  font-weight: 500;
}

.amount.income {
  color: #27ae60;
}

.amount.expense {
  color: #e74c3c;
}

.amount.net {
  font-size: 1rem;
  font-weight: bold;
  border-top: 1px solid #ecf0f1;
  padding-top: 0.25rem;
  margin-top: 0.25rem;
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

.transaction-project {
  font-size: 0.8rem;
  color: #3498db;
  margin-top: 0.25rem;
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
