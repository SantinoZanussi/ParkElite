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

    // Limpiar notificaciones anteriores
    await Notification.deleteMany({});
    console.log('🧹 Notificaciones anteriores limpiadas\n');

    console.log('=== ESCENARIO: Plaza ocupada después del tiempo ===\n');
    
    // Obtener usuarios
    const users = await User.find().limit(2);
    if (users.length < 2) {
      console.log('❌ Se necesitan al menos 2 usuarios en la BD');
      return;
    }

    const user1 = users[0];
    const user2 = users[1];

    console.log('👤 Usuario 1:', {
      userId: user1.userId,
      _id: user1._id,
      name: user1.name,
      email: user1.email
    });

    console.log('👤 Usuario 2:', {
      userId: user2.userId,
      _id: user2._id,
      name: user2.name,
      email: user2.email
    });

    const spot = await ParkingSpot.findOne({ spotNumber: 3 });
    
    if (!spot) {
      console.log('❌ Plaza 3 no encontrada en la BD');
      return;
    }
    
    console.log('\n🅿️ Plaza encontrada:', {
      _id: spot._id,
      spotNumber: spot.spotNumber,
      name: spot.name
    });
    
    const now = new Date();
    
    // Crear reserva vencida (Usuario 1) - terminó hace 5 minutos
    const expiredReservation = new Reservation({
      userId: user1.userId,
      code: user1.code,
      parkingSpotId: spot._id,
      startTime: new Date(now.getTime() - 2 * 60 * 60 * 1000), // Hace 2 horas
      endTime: new Date(now.getTime() - 5 * 60 * 1000), // Hace 5 minutos
      reservationDate: now,
      status: 'confirmado'
    });
    await expiredReservation.save();
    console.log('\n📝 Reserva vencida creada:');
    console.log('  - ID:', expiredReservation._id);
    console.log('  - Usuario:', user1.name);
    console.log('  - Plaza:', spot.spotNumber);
    console.log('  - Inicio:', expiredReservation.startTime.toISOString());
    console.log('  - Fin:', expiredReservation.endTime.toISOString());
    console.log('  - Estado:', expiredReservation.status);

    // Crear próxima reserva (Usuario 2) - comienza en 2 minutos
    const nextReservation = new Reservation({
      userId: user2.userId,
      code: user2.code,
      parkingSpotId: spot._id,
      startTime: new Date(now.getTime() + 2 * 60 * 1000), // En 2 minutos
      endTime: new Date(now.getTime() + 2 * 60 * 60 * 1000), // En 2 horas
      reservationDate: now,
      status: 'confirmado'
    });
    await nextReservation.save();
    console.log('\n📝 Próxima reserva creada:');
    console.log('  - ID:', nextReservation._id);
    console.log('  - Usuario:', user2.name);
    console.log('  - Plaza:', spot.spotNumber);
    console.log('  - Inicio:', nextReservation.startTime.toISOString());
    console.log('  - Fin:', nextReservation.endTime.toISOString());
    console.log('  - Estado:', nextReservation.status);

    // Simular reporte del ESP8266
    console.log('\n🔍 Simulando reporte de ocupación del ESP8266...');
    console.log('  - Plaza: 3');
    console.log('  - Ocupada: true');
    console.log('  - Hora actual UTC:', now.toISOString());
    
    const mockReq = {
      body: {
        spotNumber: 3,
        occupied: true
      }
    };
    
    const mockRes = {
      json: (data) => {
        console.log('\n✅ Respuesta del servidor:');
        console.log(JSON.stringify(data, null, 2));
      },
      status: function(code) {
        console.log('Status:', code);
        return this;
      }
    };

    await notificationController.checkSpotConflicts(mockReq, mockRes);

    // Verificar notificaciones creadas
    console.log('\n📬 Verificando notificaciones en la BD:\n');
    
    const notificationsUser1 = await Notification.find({ userId: user1._id })
      .sort({ createdAt: -1 });
    
    const notificationsUser2 = await Notification.find({ userId: user2._id })
      .sort({ createdAt: -1 });

    console.log(`Usuario 1 (${user1.name}): ${notificationsUser1.length} notificaciones`);
    notificationsUser1.forEach((notif, i) => {
      console.log(`  ${i + 1}. ${notif.title}`);
      console.log(`     Tipo: ${notif.type}`);
      console.log(`     Mensaje: ${notif.message}`);
      console.log(`     Leída: ${notif.read}`);
    });

    console.log(`\nUsuario 2 (${user2.name}): ${notificationsUser2.length} notificaciones`);
    notificationsUser2.forEach((notif, i) => {
      console.log(`  ${i + 1}. ${notif.title}`);
      console.log(`     Tipo: ${notif.type}`);
      console.log(`     Mensaje: ${notif.message}`);
      console.log(`     Leída: ${notif.read}`);
    });

    console.log('\n✅ Prueba completada');
    console.log('\n💡 Próximos pasos:');
    console.log('1. Verifica las notificaciones en la app con ambos usuarios');
    console.log('2. Si no aparecen, revisa los logs del servidor');
    console.log('3. Usa el endpoint GET /api/notifications/debug/all para más detalles');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.connection.close();
    console.log('\n👋 Desconectado de MongoDB');
  }
}

testNotificationSystem();