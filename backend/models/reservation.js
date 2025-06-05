const mongoose = require('mongoose');

const reservationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  uid_rfid: {
    type: String,
    required: true
  },
  parkingSpotId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'ParkingSpot',
    required: true
  },
  startTime: {
    type: Date,
    required: true
  },
  endTime: {
    type: Date,
    required: true
  },
  reservationDate: {
    type: Date,
    required: true
  },
  status: {
    type: String,
    enum: ['pendiente', 'confirmado', 'cancelado', 'completado'],
    default: 'confirmado'
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Índices para optimización
reservationSchema.index({ userId: 1, reservationDate: 1 });
reservationSchema.index({ parkingSpotId: 1, reservationDate: 1 });
reservationSchema.index({ startTime: 1, endTime: 1 });

// Validación personalizada: no permitir reservas los domingos
reservationSchema.pre('save', function(next) {
  const reservationDay = new Date(this.reservationDate).getDay();
  if (reservationDay === 0) { // 0 = Domingo
    const error = new Error('No se pueden hacer reservas los domingos');
    return next(error);
  }
  next();
});

module.exports = mongoose.model('Reservation', reservationSchema);