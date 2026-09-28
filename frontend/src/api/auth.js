import request from './request';

// 管理员登录
export function login(data) {
  return request.post('/auth/login', data);
}

// 获取当前登录用户信息
export function getProfile() {
  return request.get('/auth/profile');
}

// 修改当前登录用户密码
export function changePassword(data) {
  return request.put('/auth/password', data);
}
