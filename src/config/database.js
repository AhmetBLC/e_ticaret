const { Pool } = require("pg");
const { getDatabasePoolConfig } = require("./env");

let pool;

/**
 * Returns a singleton `pg` Pool. Requires `DATABASE_URL` or `PGUSER` + `PGDATABASE` (+ `PGHOST`, etc.) in `.env`.
 */
function getPool() {
  const config = getDatabasePoolConfig();
  if (!config) {
    throw new Error(
      "Database not configured: set DATABASE_URL or PGUSER and PGDATABASE (and optional PGHOST, PGPORT, PGPASSWORD)"
    );
  }
  if (!pool) {
    pool = new Pool(config);
  }
  return pool;
}

/** Run a parameterized SQL statement. Reuses the shared pool. */
async function query(text, params) {
  return getPool().query(text, params);
}

/**
 * Lightweight check: runs `SELECT NOW()` and current database name.
 * @returns {Promise<{ now: Date, db: string }>}
 */
async function testConnection() {
  const result = await query(
    "SELECT NOW() AS now, current_database()::text AS db"
  );
  const row = result.rows[0];
  return { now: row.now, db: row.db };
}

/** Runs `fn(client)` inside a transaction (BEGIN / COMMIT / ROLLBACK). */
async function withTransaction(fn) {
  const pool = getPool();
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const result = await fn(client);
    await client.query("COMMIT");
    return result;
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}

module.exports = {
  getPool,
  query,
  testConnection,
  withTransaction,
};
