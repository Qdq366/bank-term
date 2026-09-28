const crypto = require('crypto');
const User = require('../models/User');
const { success, fail } = require('../utils/response');
const { signToken } = require('../utils/jwtHelper');

// 密码加密：scrypt 算法，存储格式 salt:hash
function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString('hex');
  const hash = crypto.scryptSync(password, salt, 64).toString('hex');
  return `${salt}:${hash}`;
}

function verifyPassword(password, stored) {
  const [salt, hash] = String(stored).split(':');
  if (!salt || !hash) return false;
  const computed = crypto.scryptSync(password, salt, 64).toString('hex');
  return crypto.timingSafeEqual(Buffer.from(hash, 'hex'), Buffer.from(computed, 'hex'));
}

// POST /api/auth/login 管理员登录
async function login(req, res, next) {
  try {
    const { username, password } = req.body || {};
    if (!username || !password) {
      return fail(res, '请输入用户名和密码', 400, 400);
    }
    const user = await User.findOne({ username: username.trim() });
    if (!user || !verifyPassword(password, user.password)) {
      return fail(res, '用户名或密码错误', 400, 400);
    }
    const token = signToken({ id: user._id.toString(), username: user.username, role: user.role });
    return success(res, {
      token,
      user: { id: user._id, username: user.username, nickname: user.nickname || user.username, role: user.role }
    }, '登录成功');
  } catch (err) {
    next(err);
  }
}

// GET /api/auth/profile 获取当前登录用户信息
async function profile(req, res, next) {
  try {
    const user = await User.findById(req.user.id).lean();
    if (!user) return fail(res, '用户不存在', 404, 404);
    return success(res, {
      id: user._id,
      username: user.username,
      nickname: user.nickname || user.username,
      role: user.role
    });
  } catch (err) {
    next(err);
  }
}

// PUT /api/auth/password 修改当前登录用户密码
async function changePassword(req, res, next) {
  try {
    const { oldPassword, newPassword } = req.body || {};
    if (!oldPassword || !newPassword) {
      return fail(res, '请输入旧密码和新密码', 400, 400);
    }
    if (newPassword.length < 6) {
      return fail(res, '新密码长度不能少于 6 位', 400, 400);
    }
    const user = await User.findById(req.user.id);
    if (!user) return fail(res, '用户不存在', 404, 404);
    if (!verifyPassword(oldPassword, user.password)) {
      return fail(res, '旧密码错误', 400, 400);
    }
    user.password = hashPassword(newPassword);
    await user.save();
    return success(res, null, '密码修改成功');
  } catch (err) {
    next(err);
  }
}

module.exports = { login, profile, changePassword, hashPassword };
