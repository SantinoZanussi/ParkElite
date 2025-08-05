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

    const parkingSpots = [ // Espacios del estacionamiento
      {
        spotNumber: 1,
        name: 'Espacio 1',
      },
      {
        spotNumber: 2,
        name: 'Espacio 2',
      },
      {
        spotNumber: 3,
        name: 'Espacio 3',
      },
      {
        spotNumber: 4,
        name: 'Espacio 4',
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