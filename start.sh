#!/bin/sh

echo "🚀 Starting UK Gov Standards MCP Server..."

# Start HTTP server immediately in background
echo "🌐 Starting HTTP server on port ${PORT:-10000}..."
node dist/http-server.js &
SERVER_PID=$!

# Wait for server to be ready
sleep 5

# Check if database needs setup
DB_PATH=${DB_PATH:-/app/standards.db}
DATABASE_URL=${DATABASE_URL:-sqlite:./standards.db}

echo "📦 Checking database..."

# Run setup in background if DB is empty
node -e "
const Database = require('better-sqlite3');
try {
  const db = new Database('$DB_PATH');
  const count = db.prepare('SELECT COUNT(*) as count FROM standards').get();
  db.close();
  process.exit(count.count > 0 ? 0 : 1);
} catch(e) {
  process.exit(1);
}
" 2>/dev/null

if [ \$? -ne 0 ]; then
  echo "📥 Database empty — running setup in background..."
  DATABASE_URL=$DATABASE_URL node dist/scripts/setup.js &
  echo "⏳ Setup running in background, search available once complete..."
else
  echo "✅ Database already populated, skipping setup."
fi

# Keep the server process in foreground
wait $SERVER_PID