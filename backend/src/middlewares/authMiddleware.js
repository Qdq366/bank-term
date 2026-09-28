const { verifyToken } = require('../utils/jwtHelper');
const { fail } = require('../utils/response');

// JWT 解析与路由权限拦截器
function authMiddleware(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) {
    return fail(res, '未登录或登录已过期', 401, 401);
  }
  try {
    req.user = verifyToken(token);
    next();
  } catch (err) {
    return fail(res, '登录状态无效，请重新登录', 401, 401);
  }
}

module.exports = authMiddleware;
