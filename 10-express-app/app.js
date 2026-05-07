const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.json({ message: 'Hello from Express!' });
});

app.get('/api/items', (req, res) => {
  res.json({ items: ['Item 1', 'Item 2', 'Item 3'] });
});

app.listen(3000, () => {
  console.log('Express server běží na portu 3000');
});
