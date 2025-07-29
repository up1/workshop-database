const express = require('express');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

// PostgreSQL connection pool
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'bookstore',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'password',
});

// Set view engine
app.set('view engine', 'ejs');
app.set('views', './views');

// Static files
app.use(express.static('public'));

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.get('/', async (req, res) => {
  try {
    // Get pg_stat_statements data
    const query = `
      SELECT 
        query, 
        calls, 
        total_exec_time, 
        mean_exec_time,
        rows,
        100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent
      FROM pg_stat_statements 
      ORDER BY total_exec_time DESC 
      LIMIT 20;
    `;
    
    const result = await pool.query(query);
    
    res.render('index', { 
      title: 'PostgreSQL pg_stat_statements Monitor',
      statements: result.rows,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Database error:', error);
    res.render('error', { 
      title: 'Error',
      error: error.message 
    });
  }
});

// API endpoint for AJAX refresh
app.get('/api/stats', async (req, res) => {
  try {
    const query = `
      SELECT 
        query, 
        calls, 
        total_exec_time, 
        mean_exec_time,
        rows,
        100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent
      FROM pg_stat_statements 
      ORDER BY total_exec_time DESC 
      LIMIT 20;
    `;
    
    const result = await pool.query(query);
    res.json({
      statements: result.rows,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Database error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Reset pg_stat_statements
app.post('/api/reset', async (req, res) => {
  try {
    await pool.query('SELECT pg_stat_statements_reset();');
    res.json({ success: true, message: 'Statistics reset successfully' });
  } catch (error) {
    console.error('Reset error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Test database connection
app.get('/api/test-connection', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW() as current_time');
    res.json({ 
      success: true, 
      message: 'Database connection successful',
      timestamp: result.rows[0].current_time
    });
  } catch (error) {
    console.error('Connection test failed:', error);
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('Shutting down gracefully...');
  await pool.end();
  process.exit(0);
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
  console.log('Press Ctrl+C to stop the server');
});

module.exports = app;
