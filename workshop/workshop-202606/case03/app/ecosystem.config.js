module.exports = {
  apps: [{
    name: 'api',
    script: 'src/index.js',
    instances: 4,          // 4 workers × (10 primary + 35 replica) = 180 connections
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
    },
  }],
};
