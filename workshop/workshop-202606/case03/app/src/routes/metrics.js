const { Router } = require('express');
const { primaryPool, replicaPool } = require('../db');

const router = Router();

router.get('/', async (req, res) => {
  try {
    const [primaryStat, replicaStat] = await Promise.all([
      primaryPool.query(
        `SELECT count(*)::int AS connections,
                count(*) FILTER (WHERE state = 'active')::int AS active,
                count(*) FILTER (WHERE state = 'idle')::int   AS idle
         FROM pg_stat_activity
         WHERE datname = current_database()`
      ),
      replicaPool.query(
        `SELECT count(*)::int AS connections,
                count(*) FILTER (WHERE state = 'active')::int AS active,
                count(*) FILTER (WHERE state = 'idle')::int   AS idle
         FROM pg_stat_activity
         WHERE datname = current_database()`
      ),
    ]);

    res.json({
      worker_pid: process.pid,
      primary: {
        pool: {
          total:   primaryPool.totalCount,
          idle:    primaryPool.idleCount,
          waiting: primaryPool.waitingCount,
          max:     parseInt(process.env.PRIMARY_POOL_MAX || '10'),
        },
        pg_stat_activity: primaryStat.rows[0],
      },
      replica: {
        pool: {
          total:   replicaPool.totalCount,
          idle:    replicaPool.idleCount,
          waiting: replicaPool.waitingCount,
          max:     parseInt(process.env.REPLICA_POOL_MAX || '35'),
        },
        pg_stat_activity: replicaStat.rows[0],
      },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
