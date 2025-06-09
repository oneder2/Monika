// 测试前端登录功能
const axios = require('axios');

// 创建axios实例，模拟前端的配置
const api = axios.create({
  baseURL: 'http://127.0.0.1:8000',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
});

// 请求拦截器 - 模拟前端的逻辑
api.interceptors.request.use(
  (config) => {
    // 如果是FormData，删除Content-Type让浏览器自动设置
    if (config.data instanceof FormData) {
      delete config.headers['Content-Type'];
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

async function testLogin() {
  try {
    console.log('测试登录功能...');
    
    // 创建FormData，模拟前端的登录请求
    const FormData = require('form-data');
    const formData = new FormData();
    formData.append('username', 'testuser');
    formData.append('password', 'testpass123');
    
    const response = await api.post('/auth/token/', formData, {
      headers: formData.getHeaders()
    });
    
    console.log('登录成功！');
    console.log('Token:', response.data.access_token);
    console.log('Token类型:', response.data.token_type);
    
    return response.data;
  } catch (error) {
    console.error('登录失败:', error.response?.data || error.message);
    return null;
  }
}

// 运行测试
testLogin();
