const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const authMiddleware = require('../middleware/auth');

// registrar un usuario
router.post('/register', userController.createUser);

// checkear login de un usuario
router.post('/login', userController.loginUser);

// obtener un usuario
router.get('/getUser', authMiddleware, userController.getUser);

module.exports = router;