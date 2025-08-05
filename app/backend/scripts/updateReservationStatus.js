const cron = require('node-cron');
const reservationController = require('../controllers/reservationController');

const scheduleStatusUpdate = () => { // programado
    cron.schedule('*/30 * * * *', async () => { // cada 30 minutos
      try {
        console.log('Iniciando actualización programada de estados de reservas...');
        await reservationController.updateCompletedReservations();
        console.log('Actualización completada exitosamente');
      } catch (error) {
        console.error('Error en actualización programada:', error);
      }
    });
    
    console.log('Tarea programada: actualización de estados cada 30 minutos');
};

const runStatusUpdateTask = async () => { // apenas inicia el servidor
    try {
        console.log('Iniciando actualización de estados de reservas...');
        await reservationController.updateCompletedReservations();
        console.log('Actualización de estados completada');
    } catch (error) {
        console.error('Error al actualizar estados de reservas:', error);
    }
}

module.exports = { scheduleStatusUpdate, runStatusUpdateTask };