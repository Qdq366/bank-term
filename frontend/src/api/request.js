import axios from 'axios';
import { ElMessage } from 'element-plus';

// Axios 实例二次封装：自动携带 Token、统一错误提示、401 跳登录
const request = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api',
  timeout: 15000
});

request.interceptors.request.use((config) => {
  const token = localStorage.getItem('bank_exam_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

request.interceptors.response.use(
  (response) => {
    const body = response.data;
    if (body && typeof body === 'object' && 'code' in body) {
      if (body.code === 200) return body;
      ElMessage.error(body.message || '请求失败');
      return Promise.reject(new Error(body.message || '请求失败'));
    }
    return body;
  },
  (error) => {
    const status = error.response?.status;
    const message = error.response?.data?.message || '网络异常，请稍后重试';
    if (status === 401) {
      localStorage.removeItem('bank_exam_token');
      localStorage.removeItem('bank_exam_user');
      // 仅在管理端页面时跳转登录页
      if (window.location.pathname.startsWith('/admin') && window.location.pathname !== '/admin/login') {
        window.location.href = '/admin/login';
      }
    }
    ElMessage.error(message);
    return Promise.reject(error);
  }
);

export default request;
