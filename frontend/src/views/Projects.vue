<template>
  <div class="projects">
    <div class="page-header">
      <h1>项目管理</h1>
      <button @click="showAddModal = true" class="add-btn">
        + 添加项目
      </button>
    </div>
    
    <div class="projects-grid">
      <div v-if="projects.length === 0" class="no-data">
        暂无项目，点击上方按钮添加第一个项目
      </div>
      
      <div 
        v-for="project in projects" 
        :key="project.id"
        class="project-card"
      >
        <div class="project-header">
          <h3>{{ project.name }}</h3>
          <div class="project-actions">
            <button @click="editProject(project)" class="edit-btn">编辑</button>
            <button @click="deleteProject(project.id)" class="delete-btn">删除</button>
          </div>
        </div>
        
        <div class="project-info">
          <div v-if="project.description" class="project-description">
            {{ project.description }}
          </div>

          <div class="project-dates">
            <div v-if="project.start_date">
              开始日期: {{ formatDate(project.start_date) }}
            </div>
            <div v-if="project.end_date">
              结束日期: {{ formatDate(project.end_date) }}
            </div>
          </div>

          <div class="project-stats" v-if="project.stats">
            <div class="stat-item">
              <span class="stat-label">总收入:</span>
              <span class="stat-value income">¥{{ project.stats.total_income.toFixed(2) }}</span>
            </div>
            <div class="stat-item">
              <span class="stat-label">总支出:</span>
              <span class="stat-value expense">¥{{ project.stats.total_expense.toFixed(2) }}</span>
            </div>
            <div class="stat-item">
              <span class="stat-label">净收入:</span>
              <span class="stat-value" :class="project.stats.net_amount >= 0 ? 'income' : 'expense'">
                ¥{{ project.stats.net_amount.toFixed(2) }}
              </span>
            </div>
            <div class="stat-item">
              <span class="stat-label">交易数量:</span>
              <span class="stat-value">{{ project.stats.transaction_count }}</span>
            </div>
          </div>

          <div class="project-actions-bottom">
            <button @click="toggleTransactions(project.id)" class="view-transactions-btn">
              {{ showTransactions[project.id] ? '隐藏交易记录' : '查看交易记录' }}
            </button>
          </div>

          <div v-if="showTransactions[project.id]" class="project-transactions">
            <div v-if="projectTransactions[project.id] && projectTransactions[project.id].length === 0" class="no-transactions">
              该项目暂无交易记录
            </div>
            <div v-else-if="projectTransactions[project.id]" class="transactions-list">
              <div
                v-for="transaction in projectTransactions[project.id]"
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
      </div>
    </div>
    
    <!-- 添加/编辑项目模态框 -->
    <div v-if="showAddModal || showEditModal" class="modal-overlay" @click="closeModal">
      <div class="modal" @click.stop>
        <h3>{{ showEditModal ? '编辑项目' : '添加项目' }}</h3>
        
        <form @submit.prevent="saveProject">
          <div class="form-group">
            <label>项目名称</label>
            <input v-model="form.name" type="text" required placeholder="例如：2025年春节旅行" />
          </div>
          
          <div class="form-group">
            <label>项目描述</label>
            <textarea v-model="form.description" placeholder="项目的详细描述"></textarea>
          </div>
          
          <div class="form-group">
            <label>开始日期</label>
            <input v-model="form.start_date" type="date" />
          </div>
          
          <div class="form-group">
            <label>结束日期</label>
            <input v-model="form.end_date" type="date" />
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
  name: 'Projects',
  setup() {
    const projects = ref([])
    const showAddModal = ref(false)
    const showEditModal = ref(false)
    const loading = ref(false)
    const editingId = ref(null)
    const showTransactions = ref({})
    const projectTransactions = ref({})
    
    const form = ref({
      name: '',
      description: '',
      start_date: '',
      end_date: ''
    })
    
    const resetForm = () => {
      form.value = {
        name: '',
        description: '',
        start_date: '',
        end_date: ''
      }
    }
    
    const formatDate = (dateString) => {
      return new Date(dateString).toLocaleDateString('zh-CN')
    }
    
    const fetchProjects = async () => {
      try {
        const response = await api.get('/projects')
        projects.value = response.data

        // 为每个项目获取统计信息
        for (const project of projects.value) {
          await fetchProjectStats(project.id)
        }
      } catch (error) {
        console.error('Failed to fetch projects:', error)
      }
    }

    const fetchProjectStats = async (projectId) => {
      try {
        const response = await api.get(`/projects/${projectId}/stats`)
        const project = projects.value.find(p => p.id === projectId)
        if (project) {
          project.stats = response.data
        }
      } catch (error) {
        console.error('Failed to fetch project stats:', error)
      }
    }

    const fetchProjectTransactions = async (projectId) => {
      try {
        const response = await api.get(`/projects/${projectId}/transactions`)
        projectTransactions.value[projectId] = response.data
      } catch (error) {
        console.error('Failed to fetch project transactions:', error)
        projectTransactions.value[projectId] = []
      }
    }

    const toggleTransactions = async (projectId) => {
      showTransactions.value[projectId] = !showTransactions.value[projectId]

      if (showTransactions.value[projectId] && !projectTransactions.value[projectId]) {
        await fetchProjectTransactions(projectId)
      }
    }
    
    const saveProject = async () => {
      loading.value = true
      
      try {
        const data = { ...form.value }
        
        // 清空空字符串的日期字段
        if (!data.start_date) data.start_date = null
        if (!data.end_date) data.end_date = null
        if (!data.description) data.description = null
        
        if (showEditModal.value) {
          await api.put(`/projects/${editingId.value}`, data)
        } else {
          await api.post('/projects', data)
        }
        
        await fetchProjects()
        closeModal()
      } catch (error) {
        console.error('Failed to save project:', error)
        alert('保存失败，请重试')
      }
      
      loading.value = false
    }
    
    const editProject = (project) => {
      form.value = {
        name: project.name,
        description: project.description || '',
        start_date: project.start_date || '',
        end_date: project.end_date || ''
      }
      editingId.value = project.id
      showEditModal.value = true
    }
    
    const deleteProject = async (id) => {
      if (!confirm('确定要删除这个项目吗？')) return

      try {
        await api.delete(`/projects/${id}`)
        await fetchProjects()
      } catch (error) {
        console.error('Failed to delete project:', error)
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
      fetchProjects()
    })
    
    return {
      projects,
      showAddModal,
      showEditModal,
      loading,
      form,
      showTransactions,
      projectTransactions,
      formatDate,
      saveProject,
      editProject,
      deleteProject,
      closeModal,
      toggleTransactions
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

.projects-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(380px, 1fr));
  gap: var(--spacing-xl);
}

.no-data {
  grid-column: 1 / -1;
  text-align: center;
  padding: var(--spacing-2xl);
  color: var(--text-muted);
  background: var(--bg-primary);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-md);
  border: 1px solid var(--border-color);
  font-size: 1.1rem;
}

.project-card {
  background: var(--bg-primary);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-md);
  padding: var(--spacing-xl);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  border: 1px solid var(--border-color);
  position: relative;
  overflow: hidden;
}

.project-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  background: linear-gradient(90deg, var(--primary-color), var(--secondary-color));
}

.project-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-xl);
}

.project-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.project-header h3 {
  color: #2c3e50;
  margin: 0;
}

.project-actions {
  display: flex;
  gap: 0.5rem;
}

.edit-btn, .delete-btn {
  padding: var(--spacing-sm) var(--spacing-md);
  border: none;
  border-radius: var(--border-radius-sm);
  cursor: pointer;
  font-size: 0.875rem;
  font-weight: 500;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
}

.edit-btn::before, .delete-btn::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent);
  transition: left 0.5s;
}

.edit-btn:hover::before, .delete-btn:hover::before {
  left: 100%;
}

.edit-btn {
  background: linear-gradient(135deg, var(--info-color) 0%, #2563eb 100%);
  color: white;
}

.edit-btn:hover {
  transform: translateY(-1px);
  box-shadow: var(--shadow-md);
}

.delete-btn {
  background: linear-gradient(135deg, var(--danger-color) 0%, var(--danger-hover) 100%);
  color: white;
}

.delete-btn:hover {
  transform: translateY(-1px);
  box-shadow: var(--shadow-md);
}

.project-info {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.project-description {
  color: #7f8c8d;
  line-height: 1.5;
}

.project-dates {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  font-size: 0.9rem;
  color: #7f8c8d;
}

.project-stats {
  margin-top: 1rem;
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 4px;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.5rem;
}

.stat-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.stat-label {
  color: #7f8c8d;
  font-size: 0.9rem;
}

.stat-value {
  font-weight: bold;
  color: #2c3e50;
}

.stat-value.income {
  color: #27ae60;
}

.stat-value.expense {
  color: #e74c3c;
}

.project-actions-bottom {
  margin-top: 1rem;
  text-align: center;
}

.view-transactions-btn {
  background: linear-gradient(135deg, var(--primary-color) 0%, var(--primary-hover) 100%);
  color: white;
  border: none;
  padding: var(--spacing-sm) var(--spacing-md);
  border-radius: var(--border-radius-sm);
  cursor: pointer;
  font-size: 0.875rem;
  font-weight: 500;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
}

.view-transactions-btn::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent);
  transition: left 0.5s;
}

.view-transactions-btn:hover::before {
  left: 100%;
}

.view-transactions-btn:hover {
  transform: translateY(-1px);
  box-shadow: var(--shadow-md);
}

.project-transactions {
  margin-top: 1rem;
  border-top: 1px solid #ecf0f1;
  padding-top: 1rem;
}

.no-transactions {
  text-align: center;
  color: #7f8c8d;
  padding: 1rem;
  font-style: italic;
}

.transactions-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.transaction-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem;
  background: white;
  border-radius: 4px;
  border: 1px solid #ecf0f1;
}

.transaction-info {
  flex: 1;
}

.transaction-title {
  font-weight: 500;
  color: #2c3e50;
  margin-bottom: 0.25rem;
}

.transaction-date {
  font-size: 0.8rem;
  color: #7f8c8d;
}

.transaction-amount {
  font-weight: bold;
  font-size: 1rem;
}

.transaction-amount.income {
  color: #27ae60;
}

.transaction-amount.expense {
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

.form-group input,
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
