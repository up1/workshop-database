# PostgreSQL Stats Web UI

A web-based interface to monitor PostgreSQL `pg_stat_statements` data using Node.js, Express, and the `pg` library.

## Features

- 📊 Real-time monitoring of PostgreSQL query statistics
- 🔄 Auto-refresh every 30 seconds
- 🎯 Query performance metrics (execution time, calls, rows)
- 🧹 Reset statistics functionality
- 📱 Responsive Bootstrap UI
- 🔌 Connection testing
- 📈 Summary cards with key metrics
- 🎨 Color-coded performance indicators

## Prerequisites

1. **PostgreSQL** with `pg_stat_statements` extension enabled
2. **Node.js** (version 14 or higher)
3. **npm** or **yarn**

## Setup Instructions

### 1. Enable pg_stat_statements Extension

Connect to your PostgreSQL database and run:

```sql
-- Enable the extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Verify it's enabled
SELECT * FROM pg_extension WHERE extname = 'pg_stat_statements';
```

### 2. Install Dependencies

```bash
cd web-pg-stats
npm install
```

### 3. Configure Environment

Copy the example environment file and edit it:

```bash
cp .env.example .env
```

Edit `.env` with your PostgreSQL connection details:

```env
# PostgreSQL Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=bookstore
DB_USER=postgres
DB_PASSWORD=your_password

# Server Configuration
PORT=3000
```

### 4. Run the Application

For development (with auto-reload):
```bash
npm run dev
```

For production:
```bash
npm start
```

The application will be available at: http://localhost:3000

## Usage

### Main Dashboard
- View top 20 queries by total execution time
- Monitor query performance metrics
- See summary statistics in cards at the top

### Available Actions
- **Refresh**: Manually refresh the data
- **Reset Stats**: Clear all pg_stat_statements data
- **Test Connection**: Verify database connectivity

### API Endpoints

- `GET /` - Main dashboard
- `GET /api/stats` - JSON API for query statistics
- `POST /api/reset` - Reset pg_stat_statements
- `GET /api/test-connection` - Test database connection

## Understanding the Metrics

| Metric | Description |
|--------|-------------|
| **Query** | The SQL query text (truncated for display) |
| **Calls** | Number of times the query was executed |
| **Total Exec Time** | Total time spent executing this query (ms) |
| **Mean Exec Time** | Average execution time per call (ms) |
| **Rows** | Total number of rows returned/affected |
| **Hit %** | Buffer cache hit percentage |

### Performance Indicators

- 🟢 **Green**: Good performance
- 🟡 **Yellow**: Moderate performance (may need attention)
- 🔴 **Red**: Poor performance (needs optimization)

## Troubleshooting

### Common Issues

1. **"pg_stat_statements" does not exist**
   - Enable the extension: `CREATE EXTENSION IF NOT EXISTS pg_stat_statements;`
   - Restart PostgreSQL if needed

2. **Connection refused**
   - Check if PostgreSQL is running
   - Verify connection parameters in `.env`
   - Check firewall settings

3. **Permission denied**
   - Ensure the database user has sufficient privileges
   - Grant access to `pg_stat_statements` view if needed

4. **No data showing**
   - Run some queries to populate statistics
   - Check if `pg_stat_statements.track` is enabled

### PostgreSQL Configuration

Add to your `postgresql.conf`:

```conf
# Required for pg_stat_statements
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.track = all
pg_stat_statements.max = 1000
```

## Development

### Project Structure

```
web-pg-stats/
├── server.js              # Main Express application
├── package.json           # Dependencies and scripts
├── .env.example           # Environment template
├── views/                 # EJS templates
│   ├── index.ejs         # Main dashboard
│   └── error.ejs         # Error page
└── README.md             # This file
```

### Adding Features

To extend the application:

1. **New metrics**: Modify the SQL query in `server.js`
2. **Additional views**: Create new EJS templates in `views/`
3. **API endpoints**: Add routes to `server.js`
4. **Styling**: Modify CSS in the EJS templates

## License

MIT License - feel free to modify and distribute.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request
