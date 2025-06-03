const Reservation = require('../models/reservation');
const ParkingSpot = require('../models/parkingSpot');

// Obtener todas las reservas de un usuario
exports.getUserReservations = async (req, res) => {
  try {
    const reservations = await Reservation.find({ 
      userId: req.user.id,
      status: { $ne: 'cancelado' }
    })
    .populate('parkingSpotId')
    .sort({ reservationDate: 1, startTime: 1 });
    
    res.json(reservations);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error del servidor' });
  }
};

// Crear nueva reserva
exports.createReservation = async (req, res) => {
  const { startTime, endTime, reservationDate } = req.body;

  try {
    // Validar que no sea domingo
    const dateObj = new Date(reservationDate);
    if (dateObj.getDay() === 0) {
      return res.status(400).json({ 
        message: 'No se pueden hacer reservas los domingos' 
      });
    }

    // Verificar si el usuario ya tiene una reserva para ese día
    const existingReservation = await Reservation.findOne({
      userId: req.user.id,
      reservationDate: {
        $gte: new Date(dateObj.setHours(0, 0, 0, 0)),
        $lt: new Date(dateObj.setHours(23, 59, 59, 999))
      },
      status: { $ne: 'cancelado' }
    });

    if (existingReservation) {
      return res.status(400).json({ 
        message: 'Ya tienes una reserva para este día. Solo se permite una reserva por día.' 
      });
    }

    // Buscar un estacionamiento disponible
    const availableSpot = await findAvailableSpot(reservationDate, startTime, endTime);
    
    if (!availableSpot) {
      return res.status(400).json({ 
        message: 'No hay espacios disponibles en el horario seleccionado' 
      });
    }

    const reservation = new Reservation({
      userId: req.user.id,
      parkingSpotId: availableSpot._id,
      startTime: new Date(startTime),
      endTime: new Date(endTime),
      reservationDate: new Date(reservationDate)
    });

    await reservation.save();
    
    // Populate la respuesta
    await reservation.populate('parkingSpotId');
    
    res.status(201).json(reservation);
  } catch (err) {
    console.error(err);
    if (err.message === 'No se pueden hacer reservas los domingos') {
      return res.status(400).json({ message: err.message });
    }
    res.status(500).json({ message: 'Error del servidor' });
  }
};

// Obtener espacios disponibles para una fecha y horario específico
exports.getAvailableSpots = async (req, res) => {
  const { date, startTime, endTime } = req.query;

  try {
    // Validar que no sea domingo
    const dateObj = new Date(date);
    if (dateObj.getDay() === 0) {
      return res.json([]);
    }

    const availableSpots = await getAvailableSpotsForTime(date, startTime, endTime);
    res.json(availableSpots);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error del servidor' });
  }
};

// Cancelar reserva
exports.cancelReservation = async (req, res) => {
  const { reservationId } = req.params;

  try {
    const reservation = await Reservation.findOne({
      _id: reservationId,
      userId: req.user.id
    });

    if (!reservation) {
      return res.status(404).json({ message: 'Reserva no encontrada' });
    }

    // Solo se pueden cancelar reservas futuras
    const now = new Date();
    if (reservation.startTime <= now) {
      return res.status(400).json({ 
        message: 'No se pueden cancelar reservas que ya comenzaron' 
      });
    }

    reservation.status = 'cancelado';
    await reservation.save();

    res.json({ message: 'Reserva cancelada exitosamente' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error del servidor' });
  }
};

// Obtener estadísticas de ocupación
exports.getOccupancyStats = async (req, res) => {
  const { date } = req.query;

  try {
    const dateObj = new Date(date);
    const startOfDay = new Date(dateObj.setHours(0, 0, 0, 0));
    const endOfDay = new Date(dateObj.setHours(23, 59, 59, 999));

    // Obtener todas las reservas del día
    const reservations = await Reservation.find({
      reservationDate: {
        $gte: startOfDay,
        $lt: endOfDay
      },
      status: { $ne: 'cancelado' }
    }).populate('parkingSpotId');

    // Calcular estadísticas por cada hora del día
    const hourlyStats = [];
    for (let hour = 6; hour < 22; hour++) { // De 6 AM a 10 PM
      const hourStart = new Date(dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate(), hour, 0, 0);
      const hourEnd = new Date(dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate(), hour + 1, 0, 0);
      
      const occupiedSpots = reservations.filter(reservation => {
        return reservation.startTime < hourEnd && reservation.endTime > hourStart;
      }).length;

      hourlyStats.push({
        hour: hour,
        occupied: occupiedSpots,
        available: 4 - occupiedSpots,
        occupancyRate: (occupiedSpots / 4) * 100
      });
    }

    res.json(hourlyStats);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error del servidor' });
  }
};

// Función auxiliar: Buscar espacio disponible
async function findAvailableSpot(date, startTime, endTime) {
  // Obtener todos los espacios
  const allSpots = await ParkingSpot.find({ isActive: true }).sort({ spotNumber: 1 });
  
  const startDate = new Date(startTime);
  const endDate = new Date(endTime);
  const reservationDate = new Date(date);

  // Para cada espacio, verificar si está disponible
  for (const spot of allSpots) {
    const isAvailable = await checkSpotAvailability(spot._id, reservationDate, startDate, endDate);
    if (isAvailable) {
      return spot;
    }
  }
  
  return null;
}

// Función auxiliar: Verificar disponibilidad de un espacio específico
async function checkSpotAvailability(spotId, date, startTime, endTime) {
  const dateObj = new Date(date);
  const startOfDay = new Date(dateObj.setHours(0, 0, 0, 0));
  const endOfDay = new Date(dateObj.setHours(23, 59, 59, 999));

  const conflictingReservations = await Reservation.countDocuments({
    parkingSpotId: spotId,
    reservationDate: {
      $gte: startOfDay,
      $lt: endOfDay
    },
    status: { $ne: 'cancelado' },
    $or: [
      { 
        startTime: { $lt: endTime }, 
        endTime: { $gt: startTime } 
      }
    ]
  });
  
  return conflictingReservations === 0;
}

// Función auxiliar: Obtener espacios disponibles para un horario
async function getAvailableSpotsForTime(date, startTime, endTime) {
  const allSpots = await ParkingSpot.find({ isActive: true }).sort({ spotNumber: 1 });
  const availableSpots = [];
  
  const startDate = new Date(startTime);
  const endDate = new Date(endTime);
  const reservationDate = new Date(date);

  for (const spot of allSpots) {
    const isAvailable = await checkSpotAvailability(spot._id, reservationDate, startDate, endDate);
    if (isAvailable) {
      availableSpots.push({
        ...spot.toObject(),
        isAvailable: true
      });
    } else {
      availableSpots.push({
        ...spot.toObject(),
        isAvailable: false
      });
    }
  }
  
  return availableSpots;
}