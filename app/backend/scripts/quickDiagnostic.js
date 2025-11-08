const mongoose = require('mongoose');
const User = require('../models/user');
const Notification = require('../models/notification');
require('dotenv').config();

async function quickDiagnostic() {
  try {
    console.log('🔍 Iniciando diagnóstico...\n');
    
    await mongoose.connect(process.env.MONGO_URL);
    console.log('✅ Conectado a MongoDB\n');

    console.log('=== 1. VERIFICANDO USUARIOS ===');
    const users = await User.find().select('userId _id name email code');
    console.log(`Total usuarios: ${users.length}`);
    
    if (users.length > 0) {
      console.log('\nPrimer usuario:');
      console.log('  - userId (ObjectId):', users[0].userId);
      console.log('  - _id:', users[0]._id);
      console.log('  - name:', users[0].name);
      console.log('  - email:', users[0].email);
      console.log('  - code:', users[0].code);
    }

    console.log('\n=== 2. VERIFICANDO NOTIFICACIONES ===');
    const notifications = await Notification.find().populate('userId');
    console.log(`Total notificaciones: ${notifications.length}`);
    
    if (notifications.length > 0) {
      console.log('\nPrimera notificación:');
      console.log('  - _id:', notifications[0]._id);
      console.log('  - userId:', notifications[0].userId);
      console.log('  - type:', notifications[0].type);
      console.log('  - title:', notifications[0].title);
      console.log('  - read:', notifications[0].read);
    }

    console.log('\n=== 3. CREANDO NOTIFICACIÓN DE PRUEBA ===');
    
    if (users.length === 0) {
      console.log('❌ No hay usuarios para crear notificación de prueba');
    } else {
      const testUser = users[0];
      
      const testNotification = new Notification({
        userId: testUser._id, // Usar _id del documento
        type: 'general',
        title: '🧪 Notificación de Diagnóstico',
        message: 'Esta notificación fue creada por el script de diagnóstico para verificar que todo funciona correctamente.',
        spotNumber: null,
        reservationId: null
      });
      
      await testNotification.save();
      console.log('✅ Notificación de prueba creada:');
      console.log('  - ID:', testNotification._id);
      console.log('  - Usuario:', testUser.name);
      console.log('  - Título:', testNotification.title);
    }

    console.log('\n=== 4. VERIFICACIÓN FINAL ===');
    const finalCount = await Notification.countDocuments();
    console.log(`Total notificaciones ahora: ${finalCount}`);

    console.log('\n=== 5. PRÓXIMOS PASOS ===');
    console.log('1. Verifica que la notificación de prueba aparezca en la app');
    console.log('2. Si NO aparece, el problema está en el endpoint GET /api/notifications');
    console.log('3. Prueba el endpoint directamente:');
    console.log('   curl -H "Authorization: Bearer TU_TOKEN" http://localhost:3000/api/notifications');
    console.log('\n4. O usa el endpoint de debug:');
    console.log('   GET /api/notifications/debug/all');

    console.log('\n✅ Diagnóstico completado');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.connection.close();
    console.log('\n👋 Desconectado de MongoDB');
  }
}

quickDiagnostic();