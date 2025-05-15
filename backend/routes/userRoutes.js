const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

// registrar un usuario
router.post('/register', userController.createUser);

// obtener un usuario
router.post('/login', userController.loginUser);

module.exports = router;