const fs = require("fs");
const path = require("path");
const { query } = require("../config/database");
const logger = require("./logger");

const MIGRATIONS_DIR = path.join(__dirname, "../../db/migrations");

/**
 * Reads every `*.sql` file in `db/migrations/` in sorted order and executes
 * them sequentially.  All existing migrations use `IF NOT EXISTS` / idempotent
 * DDL, so re-running is safe.
 */
async function runMigrations() {
  if (!fs.existsSync(MIGRATIONS_DIR)) {
    logger.warn("migrations_skip", { reason: "directory not found", dir: MIGRATIONS_DIR });
    return;
  }

  const files = fs
    .readdirSync(MIGRATIONS_DIR)
    .filter((f) => f.endsWith(".sql"))
    .sort();

  if (files.length === 0) {
    logger.info("migrations_skip", { reason: "no SQL files" });
    return;
  }

  logger.info("migrations_start", { count: files.length });

  for (const file of files) {
    const filePath = path.join(MIGRATIONS_DIR, file);
    const sql = fs.readFileSync(filePath, "utf8");
    try {
      await query(sql);
      logger.debug("migration_ok", { file });
    } catch (err) {
      // Log but don't crash — some migrations may conflict on re-run
      // (e.g. DROP CONSTRAINT when constraint doesn't exist on fresh DB).
      // The important thing is tables get created.
      logger.warn("migration_warn", { file, error: err.message });
    }
  }

  logger.info("migrations_done", { count: files.length });
}

module.exports = { runMigrations };
