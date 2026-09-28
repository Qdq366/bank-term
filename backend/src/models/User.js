const mongoose = require('mongoose');

// 用户表模型
const userSchema = new mongoose.Schema(
  {
    username: { type: String, required: true, unique: true, trim: true },
    password: { type: String, required: true }, // 存储格式 salt:hash
    nickname: { type: String, default: '' },
    role: { type: String, enum: ['admin', 'user'], default: 'admin' }
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);
