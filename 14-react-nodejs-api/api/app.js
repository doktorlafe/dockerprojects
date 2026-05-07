const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors());

app.get('/api/data', (req, res) => {
  res.json({ message: 'Data from API', items: ['Item 1', 'Item 2'] });
});

app.listen(5000, () => console.log('API běží na :5000'));
