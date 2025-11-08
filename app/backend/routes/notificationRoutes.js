const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const authMiddleware = require('../middleware/auth');

// obtener notificaciones del usuario
router.get('/', authMiddleware, notificationController.getUserNotifications);

// notificación leída
router.put('/:notificationId/read', authMiddleware, notificationController.markAsRead);

// marcar todas como leídas
router.put('/read-all', authMiddleware, notificationController.markAllAsRead);

// eliminar noti
router.delete('/:notificationId', authMiddleware, notificationController.deleteNotification);

// webhook desde ESP8266 para reportar ocupación
router.post('/check-conflicts', notificationController.checkSpotConflicts);

/* SOLO DESARROLLO */

router.post('/test', notificationController.createTestNotification);

router.get('/debug/all', notificationController.debugAllNotifications);

router.delete('/debug/clear-all', notificationController.clearAllNotifications);

module.exports = router;