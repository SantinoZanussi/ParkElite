const express = require('express');
const mongoose = require('mongoose');
const connectDB = require('./config/db');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

app.use(express.json());

//* API ROUTES
const reservationRoutes = require('./routes/reservationRoutes');

app.use('/api/reservas', reservationRoutes);

//! Middleware para manejar 404 en rutas API
/*
app.all('/api/*', (req, res) => {
    res.status(404).json({ error: "Ruta API no encontrada" });
});
*/

//* Iniciar servidor
connectDB().then(() => {
    app.listen(PORT, () => {
        console.log(`Servidor corriendo en http://localhost:${PORT}`);
    });
}).catch(err => {
    console.error("Error al conectar a la base de datos:", err);
});

/* .env info
MONGO_URL = mongodb+srv://DBUser:porriki319@cluster0.tscwgzd.mongodb.net/
PORT = 5000
*/