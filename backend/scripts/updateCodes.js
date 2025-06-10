const cron = require('node-cron');
const User = require('../models/user');

async function createCode() {
    const code = Math.floor(100000 + Math.random() * 900000);
    const existingUser = await User.findOne({ code: code });
    if (existingUser) {
        return createCode();
    }

    return code;
}

async function actualizarCodigosUsuarios() {
    const usuarios = await User.find();
  
    for (const usuario of usuarios) {
      const nuevoCodigo = await generarCodigoUnico();
      usuario.codigo = nuevoCodigo;
      await usuario.save();
    }
  }
  
// Tarea programada: cada 2 días a las 00:00
cron.schedule('0 0 */2 * *', () => {
    console.log('⏰ Ejecutando tarea: Actualizar códigos cada 2 días');
    actualizarCodigosUsuarios();
});