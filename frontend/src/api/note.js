import request from './request';

// 获取笔记列表 { categoryId, keyword, important, page, pageSize }
export function getNotes(params) {
  return request.get('/notes', { params });
}

// 新增笔记
export function createNote(data) {
  return request.post('/notes', data);
}

// 更新笔记
export function updateNote(id, data) {
  return request.put(`/notes/${id}`, data);
}

// 删除笔记
export function deleteNote(id) {
  return request.delete(`/notes/${id}`);
}
