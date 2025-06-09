import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '../api/index'

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('token') || null)
  const user = ref(null)
  
  const isAuthenticated = computed(() => !!token.value)
  
  const login = async (username, password) => {
    try {
      const formData = new FormData()
      formData.append('username', username)
      formData.append('password', password)
      
      const response = await api.post('/auth/token/', formData)
      
      token.value = response.data.access_token
      localStorage.setItem('token', token.value)
      
      // 获取用户信息
      await fetchUser()
      
      return { success: true }
    } catch (error) {
      console.error('Login error:', error)
      return { 
        success: false, 
        message: error.response?.data?.detail || '登录失败' 
      }
    }
  }
  
  const register = async (userData) => {
    try {
      const response = await api.post('/auth/register/', userData)
      return { success: true, data: response.data }
    } catch (error) {
      console.error('Register error:', error)
      return { 
        success: false, 
        message: error.response?.data?.detail || '注册失败' 
      }
    }
  }
  
  const fetchUser = async () => {
    try {
      const response = await api.get('/users/me')
      user.value = response.data
      return true
    } catch (error) {
      console.error('Fetch user error:', error)
      // 如果获取用户信息失败，清除认证状态
      logout()
      return false
    }
  }
  
  const logout = () => {
    token.value = null
    user.value = null
    localStorage.removeItem('token')
  }
  
  // 验证token有效性的函数
  const validateToken = async () => {
    if (!token.value) {
      return false
    }

    try {
      const response = await api.get('/users/me')
      user.value = response.data
      return true
    } catch (error) {
      console.error('Token validation failed:', error)
      logout()
      return false
    }
  }

  // 初始化时如果有token，验证其有效性
  if (token.value) {
    validateToken()
  }
  
  return {
    token,
    user,
    isAuthenticated,
    login,
    register,
    logout,
    fetchUser,
    validateToken
  }
})
