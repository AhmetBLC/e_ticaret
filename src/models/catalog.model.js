const fs = require("fs");
const path = require("path");
const { query } = require("../config/database");

const MIGRATION_FILES = [
  "002_create_categories.sql",
  "003_create_products.sql",
  "004_create_product_variants.sql",
  "005_create_orders.sql",
  "006_create_swaps.sql",
  "007_add_product_is_available.sql",
  "008_create_work_orders.sql",
  "009_add_users_role.sql",
  "010_create_escrows.sql",
  "011_add_order_tracking.sql",
  "012_escrow_add_refunded.sql",
];

/**
 * Creates categories and products tables if they do not exist (idempotent).
 * Run after `users` exists (`001_create_users.sql`).
 */
async function ensureCatalogTables() {
  const migrationsDir = path.join(__dirname, "../../db/migrations");
  for (const file of MIGRATION_FILES) {
    const sql = fs.readFileSync(path.join(migrationsDir, file), "utf8");
    await query(sql);
  }
}

module.exports = {
  ensureCatalogTables,
};
