#!/bin/sh

echo "🚀 Starting UK Gov Standards MCP Server..."

# Start HTTP server immediately in background
echo "🌐 Starting HTTP server on port ${PORT:-10000}..."
node dist/http-server.js &
SERVER_PID=$!

# Wait for server to be ready
sleep 5

echo "📦 Checking database..."

# Check record count directly
RECORD_COUNT=$(node -e "
const Database = require('better-sqlite3');
try {
  const db = new Database('./standards.db');
  const row = db.prepare('SELECT COUNT(*) as count FROM standards').get();
  db.close();
  console.log(row.count);
} catch(e) {
  console.log('0');
}
" 2>/dev/null)

echo "📊 Found $RECORD_COUNT records in database"

if [ "$RECORD_COUNT" = "0" ] || [ -z "$RECORD_COUNT" ]; then
  echo "📥 Database empty — running setup in background..."
  DATABASE_URL=sqlite:./standards.db node dist/scripts/setup.js &
  echo "⏳ Setup running in background, search available once complete (~3 mins)..."
else
  echo "✅ Database has $RECORD_COUNT records — skipping setup."
fi

# Keep the server process in foreground
wait $SERVER_PID