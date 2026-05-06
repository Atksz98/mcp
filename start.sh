#!/bin/sh

echo "🚀 Starting UK Gov Standards MCP Server..."

# Check if database has data
DB_PATH=${DB_PATH:-/app/standards.db}
DATABASE_URL=${DATABASE_URL:-sqlite:./standards.db}

echo "📦 Checking database at $DB_PATH..."

# Run setup if database is empty or doesn't exist
if [ ! -f "$DB_PATH" ] || [ ! -s "$DB_PATH" ]; then
  echo "📥 Database empty or missing — running setup..."
  DATABASE_URL=$DATABASE_URL node dist/scripts/setup.js
  echo "✅ Setup complete!"
else
  # Check if FTS table has records
  RECORD_COUNT=$(node -e "
    const Database = require('better-sqlite3');
    try {
      const db = new Database('$DB_PATH');
      const count = db.prepare('SELECT COUNT(*) as count FROM standards').get();
      console.log(count.count);
      db.close();
    } catch(e) {
      console.log('0');
    }
  " 2>/dev/null || echo "0")

  if [ "$RECORD_COUNT" = "0" ]; then
    echo "📥 Database exists but is empty — running setup..."
    DATABASE_URL=$DATABASE_URL node dist/scripts/setup.js
    echo "✅ Setup complete!"
  else
    echo "✅ Database has $RECORD_COUNT records — skipping setup."
  fi
fi

echo "🌐 Starting HTTP server..."
exec node dist/http-server.js