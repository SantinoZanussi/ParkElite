const express = require('express');
const router = express.Router();
const reservationController = require('../controllers/reservationController');
const authMiddleware = require('../middleware/auth');

// autenticación para todas las rutas
router.use(authMiddleware);

// nueva reserva
router.post('/', reservationController.createReservation);

// obtener reservas
router.get('/', reservationController.getUserReservations);

// obtener espacios disponibles para una fecha/hora específica
router.get('/available-spots', reservationController.getAvailableSpots);

// obtener estadísticas de ocupación
router.get('/occupancy-stats', reservationController.getOccupancyStats);

// cancelar reserva
router.delete('/:reservationId', reservationController.cancelReservation);

module.exports = router;