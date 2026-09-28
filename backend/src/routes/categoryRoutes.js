const express = require('express');
const {
  getTree,
  createCategory,
  renameCategory,
  deleteCategory
} = require('../controllers/categoryController');

const router = express.Router();

// 移动端单端直用：免登录，不带 JWT 鉴权
router.get('/tree', getTree);
router.post('/', createCategory);
router.put('/:id', renameCategory);
router.delete('/:id', deleteCategory);

module.exports = router;
