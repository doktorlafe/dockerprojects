const express = require('express');
const mysql = require('mysql2/promise');

const app = express();

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'rootpass',
  database: process.env.DB_NAME || 'nodeapp',
  waitForConnections: true,
  connectionLimit: 10
});

app.get('/', (req, res) => {
  res.json({ message: 'Node.js + MySQL' });
});

app.listen(3000, () => {
  console.log('Server běží na portu 3000');
});
