const { fail } = require('../utils/response');

// 全局异常捕获与统一格式返回中间件
// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  console.error('[服务器错误]', err);
  if (err.name === 'ValidationError') {
    return fail(res, err.message, 400, 400);
  }
  if (err.code === 11000) {
    return fail(res, '数据已存在（唯一索引冲突）', 409, 409);
  }
  return fail(res, '服务器内部错误', 500, 500);
}

module.exports = errorHandler;
