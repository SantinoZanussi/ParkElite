const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const connectDB = require('./config/db');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

app.use(express.json());
app.use(cors());

//* API ROUTES
const reservationRoutes = require('./routes/reservationRoutes');
const userRoutes = require('./routes/userRoutes');
const healthCheckRoutes = require('./routes/health-check');
app.use('/api/reservas', reservationRoutes);
app.use('/api/auth', userRoutes);
app.use('/api/health-check', healthCheckRoutes);

//! Middleware para manejar 404 en rutas API
/*
app.all('/api/*', (req, res) => {
    res.status(404).json({ error: "Ruta API no encontrada" });
});
*/

//* Iniciar servidor
connectDB().then(() => {
    app.listen(PORT, '0.0.0.0', () => {
        console.log(`Servidor corriendo en http://localhost:${PORT}`);
    });
}).catch(err => {
    console.error("Error al conectar a la base de datos:", err);
});

/* .env info
MONGO_URL = mongodb+srv://DBUser:porriki319@cluster0.tscwgzd.mongodb.net/
PORT = 5000
JWT_SECRET = 1234567890
*/