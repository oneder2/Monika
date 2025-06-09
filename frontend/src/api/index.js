import axios from 'axios'

const api = axios.create({
  baseURL: '/api',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// 请求拦截器 - 添加认证token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }

    // 如果是FormData，删除Content-Type让浏览器自动设置
    if (config.data instanceof FormData) {
      delete config.headers['Content-Type']
    }

    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// 响应拦截器 - 处理认证错误和重定向
api.interceptors.response.use(
  (response) => {
    return response
  },
  async (error) => {
    const originalRequest = error.config

    // 处理307重定向，重新发送带认证头的请求
    if (error.response?.status === 307 && !originalRequest._retry) {
      originalRequest._retry = true
      const redirectUrl = error.response.headers.location
      if (redirectUrl) {
        // 使用重定向的URL重新发送请求
        originalRequest.url = redirectUrl
        return api(originalRequest)
      }
    }

    if (error.response?.status === 401) {
      // Token过期或无效，清除本地存储并跳转到登录页
      localStorage.removeItem('token')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export default api
