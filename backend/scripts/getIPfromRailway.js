const { fetch } = require('node-fetch');

fetch('https://api.ipify.org')
    .then(res => res.text())
    .then(ip => console.log('IP pública del servidor Railway:', ip))
    .catch(err => console.error('Error al obtener IP pública:', err));