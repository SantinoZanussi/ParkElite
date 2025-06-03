const mongoose = require('mongoose');

const parkingSpotSchema = new mongoose.Schema({
  spotNumber: {
    type: Number,
    required: true,
    min: 1,
    max: 4
  },
  name: {
    type: String,
    required: true
  },
  location: {
    type: String,
    required: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Índice único para evitar duplicados
parkingSpotSchema.index({ spotNumber: 1 }, { unique: true });

module.exports = mongoose.model('ParkingSpot', parkingSpotSchema);