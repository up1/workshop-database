const express = require('express');

const app = express();
app.use(express.json());

app.use('/orders', require('./routes/orders'));
app.use('/metrics', require('./routes/metrics'));

app.get('/health', (_req, res) =>
  res.json({ status: 'ok', pid: process.pid })
);

const PORT = parseInt(process.env.PORT || '3000');
app.listen(PORT, () =>
  console.log(`Worker ${process.pid} listening on :${PORT}`)
);
