import request from './request';

// 获取分类树
export function getCategoryTree() {
  return request.get('/categories/tree');
}

// 新增分类 { name, parentId }
export function createCategory(data) {
  return request.post('/categories', data);
}

// 重命名分类
export function renameCategory(id, data) {
  return request.put(`/categories/${id}`, data);
}

// 删除分类
export function deleteCategory(id) {
  return request.delete(`/categories/${id}`);
}
