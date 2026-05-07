const express = require('express');
const app = express();

app.get('/users', async (req, res) => {
  const response = await fetch('http://user-service:3000/users');
  res.json(await response.json());
});

app.listen(8000, () => console.log('Gateway na :8000'));
