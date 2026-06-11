const { Pool } = require('pg');

const baseConfig = {
  port: parseInt(process.env.DB_PORT || '5432'),
  user: process.env.DB_USER || 'user',
  password: process.env.DB_PASSWORD || 'pass',
  database: process.env.DB_NAME || 'orders',
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
};

// Writes → primary
const primaryPool = new Pool({
  ...baseConfig,
  host: process.env.PRIMARY_HOST || 'localhost',
  max: parseInt(process.env.PRIMARY_POOL_MAX || '10'),
});

// Reads → replica
const replicaPool = new Pool({
  ...baseConfig,
  host: process.env.REPLICA_HOST || 'localhost',
  max: parseInt(process.env.REPLICA_POOL_MAX || '35'),
});

primaryPool.on('error', (err) => console.error('Primary pool error:', err.message));
replicaPool.on('error', (err) => console.error('Replica pool error:', err.message));

module.exports = { primaryPool, replicaPool };
