const Reservation = require('../models/reservation');
const ParkingSpot = require('../models/parkingSpot');
const User = require('../models/user');

// actualiza reservas a completadas
exports.updateCompletedReservations = async (req, res) => {
  try {
    const now = new Date().toISOString();
    const completedReservations = await Reservation.updateMany(
      {
        endTime: { $lt: now },
        status: 'confirmado'
      },
      {
        $set: { status: 'completado' }
      }
  );
  if (completedReservations.modifiedCount !== 0) { console.log(`${completedReservations.modifiedCount} reservas actualizadas a estado "completado".`); }
  return completedReservations;
  } catch (error) {
    console.error('Error al actualizar reservas completadas:', error);
    throw error;
  }
}

// para marcar manualmente una reserva como completada (por si acaso)
exports.markReservationAsCompleted = async (req, res) => {
  try {
    const { reservationId } = req.params;
    
    const reservation = await Reservation.findOne({
      _id: reservationId,
      status: 'confirmado'
    });
    
    if (!reservation) {
      return res.status(404).json({ 
        message: 'Reserva no encontrada o no fue completada' 
      });
    }
    
    reservation.status = 'completado';
    await reservation.save();
    
    res.json({ 
      message: 'Reserva marcada como completada',
      reservation: reservation 
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error del servidor' });
  }
};

exports.getUserReservations = async (req, res) => {
  try {
    await exports.updateCompletedReservations(); // actualizar reservas
    const reservations = await Reservation.find({ 
      userId: req.user.id,
      status: { $nin: ['cancelado', 'completado'] }
    })
    .populate('parkingSpotId')
    .sort({ reservationDate: 1, startTime: 1 });
    res.json(reservations);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error del servidor' });
  }
};

exports.createReservation = async (req, res) => {
  const { startTime, endTime, reservationDate } = req.body;
  //console.log("📥 startTime en 'createReservation' recibido:", startTime);
  //console.log("📥 Interpretado como fecha:", new Date(startTime).toISOString());
  //console.log("📥 endTime en 'createReservation' recibido:", endTime);
  //console.log("📥 Interpretado como fecha:", new Date(endTime).toISOString());
  //console.log("📥 reservationDate en 'createReservation' recibido:", reservationDate);
  //console.log("📥 Interpretado como fecha:", new Date(reservationDate).toISOString());

  try {
    const userInfo = await User.findOne({ userId: req.user.id });
    if (!userInfo) { return res.status(404).json({ message: 'Usuario no encontrado' });}

    const dateObj = new Date(reservationDate);
    if (dateObj.getDay() === 0) {
      return res.status(400).json({ 
        message: 'No se pueden hacer reservas los domingos' 
      });
    }

    const year = dateObj.getUTCFullYear();
    const month = dateObj.getUTCMonth();
    const day = dateObj.getUTCDate();

    const startDay = new Date(Date.UTC(year, month, day, 0, 0, 0));
    const endDay = new Date(Date.UTC(year, month, day, 23, 59, 59, 999));

    // si el usuario ya tiene una reserva para ese día
    const existingReservation = await Reservation.findOne({
      userId: req.user.id,
      code: userInfo.code,
      reservationDate: {
        $gte: startDay,
        $lt: endDay
      },
      status: { $ne: 'cancelado' }
    });

    if (existingReservation) {
      return res.status(400).json({ 
        message: 'Ya tienes una reserva para este día. Solo se permite una reserva por día.' 
      });
    }

    const availableSpot = await findAvailableSpot(reservationDate, startTime, endTime);
    
    if (!availableSpot) {
      return res.status(400).json({ 
        message: 'No hay espacios disponibles en el horario seleccionado' 
      });
    }

    const reservation = new Reservation({
      userId: req.user.id,
      code: userInfo.code,
      parkingSpotId: availableSpot._id,
      startTime: new Date(startTime).toISOString(),
      endTime: new Date(endTime).toISOString(),
      reservationDate: new Date(reservationDate).toISOString()
    });

    await reservation.save();
    await reservation.populate('parkingSpotId');
    
    res.status(201).json(reservation);
  } catch (err) {
    console.error(err);
    if (err.message === 'No se pueden hacer reservas los domingos.') {
      return res.status(400).json({ message: err.message });
    }
    res.status(500).json({ message: 'Error del servidor' });
  }
};

exports.getAvailableSpots = async (req, res) => {
  const { date, startTime, endTime } = req.query;

  try {
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

exports.cancelSpecificReservation = async (req, res) => {
  const { reservationId } = req.params;

  try {
    const reservation = await Reservation.findOne({
      _id: reservationId,
    });

    if (!reservation) {
      return res.status(404).json({ message: 'Reserva no encontrada' });
    } else if (reservation.status === 'cancelado') {
      return res.status(400).json({ message: 'La reserva ya está cancelada' });
    } else if (reservation.status === 'completado') {
      return res.status(400).json({ message: 'La reserva ya está completada' });
    }

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

exports.getOccupancyStats = async (req, res) => {
  const { date } = req.query;

  try {
    const dateObj = new Date(date);
    const year = dateObj.getUTCFullYear();
    const month = dateObj.getUTCMonth();
    const day = dateObj.getUTCDate();
    const startOfDay = new Date(Date.UTC(year, month, day, 0, 0, 0));
    const endOfDay = new Date(Date.UTC(year, month, day, 23, 59, 59, 999));

    //console.log("📥 startOfDay recibido:", startOfDay);
    //console.log("📥 Interpretado en 'getOcuppancyStats' como fecha:", new Date(startOfDay).toISOString());
    //console.log("📥 endOfDay en 'getOcuppancyStats' recibido:", endOfDay);
    //console.log("📥 Interpretado como fecha:", new Date(endOfDay).toISOString());


    // obtener todas las reservas del día
    const reservations = await Reservation.find({
      reservationDate: {
        $gte: startOfDay,
        $lt: endOfDay
      },
      status: { $nin: ['cancelado', 'completado'] }
    }).populate('parkingSpotId');

    // calcular estadísticas por cada hora del día
    const hourlyStats = [];
    for (let hour = 6; hour < 22; hour++) { // 6 AM a 10 PM
      const hourStart = new Date(Date.UTC(dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate(), hour, 0, 0));
      const hourEnd = new Date(Date.UTC(dateObj.getFullYear(), dateObj.getMonth(), dateObj.getDate(), hour + 1, 0, 0));
      
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

exports.confirm_arrival = async (req, res) => {
  console.log('Confirming arrival...');
  console.log(req.body);
  const reservationId = req.body.reservationId;
  const reservation = await Reservation.findOne({
    _id: reservationId,
    status: { $nin: ['cancelado', 'completado'] }
  });
  if (!reservation) return res.status(404).json({ message: 'Reserva no encontrada', allowed: false });
  if (reservation.status === 'confirmado') {
    return res.json({ message: 'La reserva confirmada', allowed: true, reservation });
  }
}

exports.cancel_expired = async (req, res) => {
  console.log('cancel_expired');
  console.log(req.body);
  const reservationId = req.body.reservationId;
  const reservation = await Reservation.findOne({
    _id: reservationId,
    status: { $nin: ['cancelado', 'completado'] }
  });
  if (!reservation) return res.status(404).json({ message: 'Reserva no encontrada', allowed: false });
  if (reservation.status === 'confirmado') {
    reservation.status = 'cancelado';
    await reservation.save();
    return res.json({ message: 'La reserva ha sido cancelada', allowed: true, reservation });
  }
}

exports.checkCodeUser = async (req, res) => {
  const user_code = req.body.code; 

  try {
    const checkCode = await Reservation.findOne({ code: user_code });

    if (!checkCode) {
      return res.status(404).json({ allowed: false, message: 'Reserva no encontrada' });
    } else {
      return res.json({ allowed: true, spotId: checkCode.parkingSpotId });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error del servidor' });
  }
}

async function findAvailableSpot(date, startTime, endTime) {
  // obtener todos los espacios
  const allSpots = await ParkingSpot.find({ isActive: true }).sort({ spotNumber: 1 });
  
  const startDate = new Date(startTime);
  const endDate = new Date(endTime);
  const reservationDate = new Date(date);

  // para cada espacio, verificar si está disponible
  for (const spot of allSpots) {
    const isAvailable = await checkSpotAvailability(spot._id, reservationDate, startDate, endDate);
    if (isAvailable) {
      return spot;
    }
  }
  
  return null;
}

async function checkSpotAvailability(spotId, date, startTime, endTime) {
  const dateObj = new Date(date);
  const year = dateObj.getUTCFullYear();
  const month = dateObj.getUTCMonth();
  const day = dateObj.getUTCDate();
  const startOfDay = new Date(Date.UTC(year, month, day, 0, 0, 0));
  const endOfDay = new Date(Date.UTC(year, month, day, 23, 59, 59, 999));

  //console.log("📥 startTime en 'checkSpotAvailability' recibido:", startTime);
  //console.log("📥 Interpretado como fecha:", new Date(startTime).toISOString());
  //console.log("📥 endTime en 'checkSpotAvailability' recibido:", endTime);
  //console.log("📥 Interpretado como fecha:", new Date(endTime).toISOString());
  //console.log("📥 startOfDay recibido:", startOfDay);
  //console.log("📥 Interpretado en 'checkSpotAvailability' como fecha:", new Date(startOfDay).toISOString());
  //console.log("📥 endOfDay en 'checkSpotAvailability' recibido:", endOfDay);
  //console.log("📥 Interpretado como fecha:", new Date(endOfDay).toISOString());

  const conflictingReservations = await Reservation.countDocuments({
    parkingSpotId: spotId,
    reservationDate: {
      $gte: startOfDay,
      $lt: endOfDay
    },
    status: { $nin: ['cancelado', 'completado'] },
    $or: [
      { 
        startTime: { $lt: endTime }, 
        endTime: { $gt: startTime } 
      }
    ]
  });
  
  return conflictingReservations === 0;
}

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