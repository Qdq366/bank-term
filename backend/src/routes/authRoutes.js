const express = require('express');
const { login, profile, changePassword } = require('../controllers/authController');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

router.post('/login', login);
router.get('/profile', authMiddleware, profile);
router.put('/password', authMiddleware, changePassword);

module.exports = router;
