require('dotenv').config();
const app = require('./src/app');
const connectDB = require('./src/config/db');

const PORT = process.env.PORT || 3000;

async function bootstrap() {
  await connectDB();
  app.listen(PORT, () => {
    console.log(`银行备考知识库后端已启动: http://localhost:${PORT}`);
  });
}

bootstrap().catch((err) => {
  console.error('服务启动失败:', err);
  process.exit(1);
});
