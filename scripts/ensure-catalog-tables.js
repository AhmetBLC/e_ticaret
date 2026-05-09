/**
 * Creates categories + products tables. Requires `users` table and DATABASE_URL in .env.
 * Usage: npm run db:ensure-catalog
 */
require("../src/config/env");
const { ensureCatalogTables } = require("../src/models/catalog.model");

ensureCatalogTables()
  .then(() => {
    console.log("[db:ensure-catalog] Tables `categories` and `products` are ready.");
    process.exit(0);
  })
  .catch((err) => {
    console.error("[db:ensure-catalog] Failed:", err.message || err);
    process.exit(1);
  });
