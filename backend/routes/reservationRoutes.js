const express = require('express');
const router = express.Router();
const reservationController = require('../controllers/reservationController');

// crear una nueva reserva
router.post('/', reservationController.createReservation);

// obtener reservas
router.get('/:userId', reservationController.getUserReservations);

module.exports = router;
