// scripts/seedParkingSpots.js
const mongoose = require('mongoose');
const ParkingSpot = require('../models/parkingSpot');
require('dotenv').config();

const seedParkingSpots = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URL);
    console.log('Conectado a MongoDB');

    // Limpiar espacios existentes
    await ParkingSpot.deleteMany({});
    console.log('Espacios existentes eliminados');

    // Crear los 4 espacios de estacionamiento
    const parkingSpots = [
      {
        spotNumber: 1,
        name: 'Espacio A1',
        location: 'Nivel 1, Sección A'
      },
      {
        spotNumber: 2,
        name: 'Espacio A2',
        location: 'Nivel 1, Sección A'
      },
      {
        spotNumber: 3,
        name: 'Espacio B1',
        location: 'Nivel 1, Sección B'
      },
      {
        spotNumber: 4,
        name: 'Espacio B2',
        location: 'Nivel 1, Sección B'
      }
    ];

    await ParkingSpot.insertMany(parkingSpots);
    console.log('Espacios de estacionamiento creados exitosamente');

    mongoose.connection.close();
  } catch (error) {
    console.error('Error al crear espacios:', error);
    process.exit(1);
  }
};

seedParkingSpots();