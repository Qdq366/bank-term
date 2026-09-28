const mongoose = require('mongoose');

// MongoDB (Mongoose) 数据库连接配置
async function connectDB() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    throw new Error('未配置 MONGODB_URI，请检查 .env 文件');
  }
  mongoose.set('strictQuery', true);
  await mongoose.connect(uri);
  console.log('MongoDB 连接成功:', mongoose.connection.name);
}

module.exports = connectDB;
