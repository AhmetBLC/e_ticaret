/**
 * Verifies PostgreSQL connectivity using env from .env (via src/config/env).
 * Usage: npm run db:test
 */
require("../src/config/env");
const { testConnection } = require("../src/config/database");

testConnection()
  .then(({ now, db }) => {
    console.log("[db:test] Connection OK");
    console.log(`  server time: ${now.toISOString()}`);
    console.log(`  database:    ${db}`);
    process.exit(0);
  })
  .catch((err) => {
    console.error("[db:test] Connection failed:", err.message || err);
    if (err.code) {
      console.error("  code:", err.code);
    }
    process.exit(1);
  });
