const mongoose = require('mongoose');
const Reservation = require('../models/reservation');
const ParkingSpot = require('../models/parkingSpot');
const User = require('../models/user');
const Notification = require('../models/notification');
const notificationController = require('../controllers/notificationController');
require('dotenv').config();

async function testNotificationSystem() {
  try {
    await mongoose.connect(process.env.MONGO_URL);
    console.log('✅ Conectado a MongoDB\n');

    console.log('=== ESCENARIO 1: Plaza ocupada después del tiempo ===');
    
    // Usuario 1 (con reserva vencida)
    const user1 = await User.findOne().limit(1);
    if (!user1) {
      console.log('❌ No hay usuarios en la BD');
      return;
    }

    const spot = await ParkingSpot.findOne({ spotNumber: 3 });
    
    const expiredReservation = new Reservation({
      userId: user1.userId,
      code: user1.code,
      parkingSpotId: spot._id,
      startTime: new Date(Date.now() - 2 * 60 * 60 * 1000), // Hace 2 horas
      endTime: new Date(Date.now() - 30 * 60 * 1000), // Hace 30 min
      reservationDate: new Date(),
      status: 'confirmado'
    });
    await expiredReservation.save();
    console.log('📝 Reserva vencida creada:', expiredReservation._id);

    // Uusuario 2 (con próxima reserva)
    const user2 = await User.findOne({ userId: { $ne: user1.userId } }).limit(1);
    if (user2) {
      const nextReservation = new Reservation({
        userId: user2.userId,
        code: user2.code,
        parkingSpotId: spot._id,
        startTime: new Date(), // Ahora
        endTime: new Date(Date.now() + 2 * 60 * 60 * 1000), // En 2 horas
        reservationDate: new Date(),
        status: 'confirmado'
      });
      await nextReservation.save();
      console.log('📝 Próxima reserva creada:', nextReservation._id);
    }

    // Reporte fake del ESP8266
    console.log('\n🔍 Simulando reporte de ocupación del ESP8266...');
    const mockReq = {
      body: {
        spotNumber: 3,
        occupied: true
      }
    };
    
    const mockRes = {
      json: (data) => {
        console.log('✅ Respuesta del servidor:', JSON.stringify(data, null, 2));
      },
      status: function(code) {
        console.log('Status:', code);
        return this;
      }
    };

    await notificationController.checkSpotConflicts(mockReq, mockRes);

    console.log('\n📬 Verificando notificaciones creadas:');
    const notifications = await Notification.find().sort({ createdAt: -1 }).limit(5);
    
    notifications.forEach((notif, index) => {
      console.log(`\n--- Notificación ${index + 1} ---`);
      console.log('Usuario:', notif.userId);
      console.log('Tipo:', notif.type);
      console.log('Título:', notif.title);
      console.log('Mensaje:', notif.message);
      console.log('Plaza:', notif.spotNumber);
      console.log('Leída:', notif.read);
    });

    console.log('\n✅ Prueba completada');

    // Limpiar datos de prueba (opcional)
    console.log('\n🧹 ¿Deseas limpiar los datos de prueba? (comentar para mantener)');
    // await Reservation.deleteMany({ _id: { $in: [expiredReservation._id, nextReservation._id] } });
    // await Notification.deleteMany({ spotNumber: 3 });

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.connection.close();
    console.log('\n👋 Desconectado de MongoDB');
  }
}

testNotificationSystem();