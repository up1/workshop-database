const { Router } = require('express');
const { primaryPool, replicaPool } = require('../db');

const router = Router();

// READ → replica
router.get('/', async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 20, 100);
    const offset = parseInt(req.query.offset) || 0;
    const { rows } = await replicaPool.query(
      `SELECT id, customer_id, customer_name, status, total_amount, created_at
       FROM orders
       ORDER BY created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );
    res.json({ source: 'replica', count: rows.length, rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// WRITE → primary
router.post('/', async (req, res) => {
  try {
    const { customer_id, customer_name, status = 'new', total_amount } = req.body;
    if (!customer_id || !customer_name || total_amount == null) {
      return res.status(400).json({ error: 'customer_id, customer_name, total_amount required' });
    }
    const { rows } = await primaryPool.query(
      `INSERT INTO orders (customer_id, customer_name, status, total_amount)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [customer_id, customer_name, status, total_amount]
    );
    res.status(201).json({ source: 'primary', row: rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
