const Notification = require('../models/notification');
const Reservation = require('../models/reservation');
const User = require('../models/user');

exports.createNotification = async (userId, type, title, message, reservationId = null, spotNumber = null) => {
  try {
    const notification = new Notification({
      userId,
      type,
      title,
      message,
      reservationId,
      spotNumber
    });
    
    await notification.save();
    console.log(`✅ Notificación creada para usuario ${userId}: ${title}`);
    return notification;
  } catch (error) {
    console.error('Error al crear notificación:', error);
    throw error;
  }
};

exports.getUserNotifications = async (req, res) => {
  try {
    const notifications = await Notification.find({ 
      userId: req.user.id 
    })
    .sort({ createdAt: -1 })
    .limit(50);
    
    res.json({
      success: true,
      notifications,
      unreadCount: notifications.filter(n => !n.read).length
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error del servidor' });
  }
};

exports.markAsRead = async (req, res) => {
  try {
    const { notificationId } = req.params;
    
    const notification = await Notification.findOneAndUpdate(
      { _id: notificationId, userId: req.user.id },
      { read: true },
      { new: true }
    );
    
    if (!notification) {
      return res.status(404).json({ message: 'Notificación no encontrada' });
    }
    
    res.json({ success: true, notification });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error del servidor' });
  }
};

exports.markAllAsRead = async (req, res) => {
  try {
    await Notification.updateMany(
      { userId: req.user.id, read: false },
      { read: true }
    );
    
    res.json({ success: true, message: 'Todas las notificaciones marcadas como leídas' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error del servidor' });
  }
};

exports.deleteNotification = async (req, res) => {
  try {
    const { notificationId } = req.params;
    
    const notification = await Notification.findOneAndDelete({
      _id: notificationId,
      userId: req.user.id
    });
    
    if (!notification) {
      return res.status(404).json({ message: 'Notificación no encontrada' });
    }
    
    res.json({ success: true, message: 'Notificación eliminada' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error del servidor' });
  }
};

// Detectar conflictos de ocupación
exports.checkSpotConflicts = async (req, res) => {
  try {
    const { spotNumber, occupied } = req.body;
    
    if (!spotNumber || typeof occupied !== 'boolean') {
      return res.status(400).json({ 
        message: 'Faltan parámetros: spotNumber y occupied' 
      });
    }

    const now = new Date();
    const nowUTC = new Date(now.toISOString());
    
    //console.log(`🔍 Verificando conflictos para plaza ${spotNumber}, ocupada: ${occupied}`);
    
    // Buscar reserva actual que debería estar activa
    const currentReservation = await Reservation.findOne({
      'parkingSpotId.spotNumber': spotNumber,
      startTime: { $lte: nowUTC },
      endTime: { $gte: nowUTC },
      status: { $nin: ['cancelado', 'completado'] }
    }).populate('parkingSpotId');

    // Buscar próxima reserva que comienza ahora
    const nextReservation = await Reservation.findOne({
      'parkingSpotId.spotNumber': spotNumber,
      startTime: { 
        $gte: nowUTC,
        $lte: new Date(nowUTC.getTime() + 30 * 60 * 1000) // En 30 min
      },
      status: 'confirmado'
    }).populate('parkingSpotId');

    let notificationsCreated = [];

    // CASO 1: Plaza ocupada pero reserva actual ya debería haber terminado
    if (occupied && currentReservation && currentReservation.endTime < nowUTC) {
      console.log(`⚠️ Plaza ${spotNumber} ocupada después de tiempo de reserva`);
      
      const notification1 = await exports.createNotification(
        currentReservation.userId,
        'vehicle_retention',
        '⚠️ Tu reserva ha finalizado',
        `Tu reserva en la Plaza ${spotNumber} ha terminado. Por favor, retira tu vehículo urgentemente para evitar inconvenientes.`,
        currentReservation._id,
        spotNumber
      );
      notificationsCreated.push(notification1);

      // Notificar que la plaza está ocupada (si es que hay)
      if (nextReservation) {
        const notification2 = await exports.createNotification(
          nextReservation.userId,
          'spot_occupied',
          '⏳ Tu plaza está temporalmente ocupada',
          `La Plaza ${spotNumber} sigue ocupada por otro vehículo. Por favor aguarda unos minutos y espera instrucciones del encargado del estacionamiento.`,
          nextReservation._id,
          spotNumber
        );
        notificationsCreated.push(notification2);
        
        console.log(`📢 Notificaciones enviadas: retención y ocupación temporal`);
      }
    }

    // CASO 2: Plaza liberada y notificar al próximo usuario
    if (!occupied && nextReservation && 
        new Date(nextReservation.startTime) <= new Date(nowUTC.getTime() + 5 * 60 * 1000)) {
      console.log(`✅ Plaza ${spotNumber} liberada, notificando próximo usuario`);
      
      const notification3 = await exports.createNotification(
        nextReservation.userId,
        'general',
        '✅ Tu plaza está disponible',
        `La Plaza ${spotNumber} ya está disponible. Puedes ingresar cuando estés listo.`,
        nextReservation._id,
        spotNumber
      );
      notificationsCreated.push(notification3);
    }

    res.json({
      success: true,
      message: `Verificación completada para plaza ${spotNumber}`,
      notificationsCreated: notificationsCreated.length,
      details: {
        currentReservation: currentReservation ? currentReservation._id : null,
        nextReservation: nextReservation ? nextReservation._id : null
      }
    });

  } catch (err) {
    console.error('Error en checkSpotConflicts:', err);
    res.status(500).json({ message: 'Error del servidor' });
  }
};

module.exports = exports;