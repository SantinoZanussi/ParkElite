const Reservation = require('../models/reservation');

// todas las reservas de un usuario
exports.getUserReservations = async (req, res) => {
  try {
    const reservations = await Reservation.find({ 
      userId: req.user.id 
    }).populate('parkingSpotId');
    
    res.json(reservations);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error del servidor' });
  }
};

// nueva reserva
exports.createReservation = async (req, res) => {
  const { parkingSpotId, startTime, endTime } = req.body;

  try {
    // si esta disponible la reserva
    const isAvailable = await checkAvailability(parkingSpotId, startTime, endTime);
    
    if (!isAvailable) {
      return res.status(400).json({ 
        message: 'Este espacio no está disponible en el horario seleccionado' 
      });
    }

    const reservation = new Reservation({
      userId: req.user.id,
      parkingSpotId,
      startTime,
      endTime
    });

    await reservation.save();
    res.status(201).json(reservation);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error del servidor' });
  }
};

async function checkAvailability(spotId, start, end) {
  const startDate = new Date(start);
  const endDate = new Date(end);
  
  const conflictingReservations = await Reservation.countDocuments({
    parkingSpotId: spotId,
    status: { $ne: 'cancelled' },
    $or: [
      { startTime: { $lt: endDate, $gte: startDate } },
      { endTime: { $gt: startDate, $lte: endDate } },
      { $and: [
          { startTime: { $lte: startDate } },
          { endTime: { $gte: endDate } }
        ]
      }
    ]
  });
  
  return conflictingReservations === 0;
}