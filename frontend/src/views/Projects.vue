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

.projects-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
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

.project-card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  padding: 1.5rem;
  transition: transform 0.2s;
}

.project-card:hover {
  transform: translateY(-2px);
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
  background: #3498db;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.9rem;
}

.view-transactions-btn:hover {
  background: #2980b9;
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
