const mongoose = require('mongoose');
require('dotenv').config();

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URL, {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });
    console.log('[DB] Conectado a la base de datos.');
  } catch (err) {
    console.error('[DB] Error de la base de datos:', err.message);
    process.exit(1);
  }
};

module.exports = connectDB;