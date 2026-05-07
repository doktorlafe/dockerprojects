const express = require('express');
const app = express();
app.get('/products', (req, res) => res.json({products: []}));
app.listen(3000);
