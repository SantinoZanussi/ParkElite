const express = require('express');
const router = express.Router();
const reservationController = require('../controllers/reservationController');
const authMiddleware = require('../middleware/auth');

// autenticación para todas las rutas
//router.use(authMiddleware);

// verificar código de reserva
router.post('/checkCode', reservationController.checkCodeUser);

// nueva reserva
router.post('/', authMiddleware, reservationController.createReservation);

// obtener reservas
router.get('/', authMiddleware, reservationController.getUserReservations);

// obtener espacios disponibles para una fecha/hora específica
router.get('/available-spots', authMiddleware, reservationController.getAvailableSpots);

// obtener estadísticas de ocupación
router.get('/occupancy-stats', authMiddleware, reservationController.getOccupancyStats);

// cancelar reserva
router.delete('/:reservationId', authMiddleware, reservationController.cancelReservation);

// cancelar reserva específica
router.delete('/cancel/:reservationId', reservationController.cancelSpecificReservation);

// confirmar llegada
router.post('/confirm-arrival', reservationController.confirm_arrival);

// cancelar llegada por expiración
router.post('/cancel-arrival', reservationController.cancel_expired);

// marcar reserva como completada (por si acaso)
router.put('/complete/:reservationId', reservationController.markReservationAsCompleted);

module.exports = router;