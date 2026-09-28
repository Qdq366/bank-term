import { defineStore } from 'pinia';
import { login as loginApi } from '../api/auth';

// 当前登录用户信息、Token 与登出逻辑
export const useUserStore = defineStore('user', {
  state: () => ({
    token: localStorage.getItem('bank_exam_token') || '',
    userInfo: JSON.parse(localStorage.getItem('bank_exam_user') || 'null')
  }),
  getters: {
    isLoggedIn: (state) => !!state.token
  },
  actions: {
    async login(username, password) {
      const res = await loginApi({ username, password });
      this.token = res.data.token;
      this.userInfo = res.data.user;
      localStorage.setItem('bank_exam_token', this.token);
      localStorage.setItem('bank_exam_user', JSON.stringify(this.userInfo));
    },
    logout() {
      this.token = '';
      this.userInfo = null;
      localStorage.removeItem('bank_exam_token');
      localStorage.removeItem('bank_exam_user');
    }
  }
});
