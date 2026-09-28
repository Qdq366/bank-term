const express = require('express');
const authRoutes = require('./authRoutes');
const categoryRoutes = require('./categoryRoutes');
const noteRoutes = require('./noteRoutes');

// 路由总入口，统一注入 /api 前缀
const router = express.Router();

router.use('/auth', authRoutes);
router.use('/categories', categoryRoutes);
router.use('/notes', noteRoutes);

module.exports = router;
