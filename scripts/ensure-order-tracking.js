/**
 * Adds orders.tracking_number (migration 011). Requires DATABASE_URL / PG* in .env.
 * Usage: npm run db:ensure-order-tracking
 */
require("../src/config/env");
const fs = require("fs");
const path = require("path");
const { query } = require("../src/config/database");

const sqlPath = path.join(
  __dirname,
  "../db/migrations/011_add_order_tracking.sql"
);

const sql = fs.readFileSync(sqlPath, "utf8");

query(sql)
  .then(() => {
    console.log("[db:ensure-order-tracking] Column tracking_number is ready.");
    process.exit(0);
  })
  .catch((err) => {
    console.error("[db:ensure-order-tracking] Failed:", err.message || err);
    process.exit(1);
  });
