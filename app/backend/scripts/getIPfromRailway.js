const https = require('https');

https.get('https://api.ipify.org', (res) => {
  let data = '';

  res.on('data', chunk => {
    data += chunk;
  });

  res.on('end', () => {
    console.log('IP pública del servidor Railway:', data);
  });
}).on('error', (err) => {
  console.error('Error al obtener IP pública:', err);
});