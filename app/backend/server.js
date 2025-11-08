const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const connectDB = require('./config/db');
const os = require('os');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(cors());

//* API ROUTES
const reservationRoutes = require('./routes/reservationRoutes');
const userRoutes = require('./routes/userRoutes');
const healthCheckRoutes = require('./routes/health-check');
const notificationRoutes = require('./routes/notificationRoutes');
app.use('/api/reservas', reservationRoutes);
app.use('/api/auth', userRoutes);
app.use('/api/health-check', healthCheckRoutes);
app.use('/api/notifications', notificationRoutes);

//! Middleware para manejar 404 en rutas API
/*
app.all('/api/*', (req, res) => {
    res.status(404).json({ error: "Ruta API no encontrada" });
});
*/

require('./scripts/updateCodes');

const { scheduleStatusUpdate, runStatusUpdateTask } = require('./scripts/updateReservationStatus');

//* Iniciar servidor

function getLocalIPv4() {
  const nets = os.networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      // Solo IPv4 y no internas (loopback)
      if (net.family === 'IPv4' && !net.internal) {
        return net.address;
      }
    }
  }
  return '0.0.0.0';
}

connectDB().then(() => {
  const host = '0.0.0.0';
  app.listen(PORT, host, () => {
    const localIP = getLocalIPv4();
    console.log(` → Servidor corriendo en:`);
    console.log(`    • http://localhost:${PORT}`);
    console.log(`    • http://${localIP}:${PORT}`);
    runStatusUpdateTask();
    scheduleStatusUpdate();
  });
}).catch(err => {
  console.error("Error al conectar a la base de datos:", err);
});


/* .env info
MONGO_URL = mongodb+srv://DBUser:porriki319@cluster0.tscwgzd.mongodb.net/app
PORT = 3000
JWT_SECRET = 1234567890
*/