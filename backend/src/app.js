const express = require('express');
const cors = require('cors');
const routes = require('./routes');
const errorHandler = require('./middlewares/errorHandler');

// Express 实例初始化、跨域(CORS)配置、中间件注册
const app = express();

app.use(cors());
app.use(express.json({ limit: '2mb' }));

app.get('/api/health', (req, res) => {
  res.json({ code: 200, message: 'ok', data: { status: 'up' } });
});

app.use('/api', routes);

app.use((req, res) => {
  res.status(404).json({ code: 404, message: '接口不存在', data: null });
});

app.use(errorHandler);

module.exports = app;
