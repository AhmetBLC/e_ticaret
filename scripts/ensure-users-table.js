/**
 * Applies users table migration (CREATE TABLE IF NOT EXISTS).
 * Usage: npm run db:ensure-users
 */
require("../src/config/env");
const { ensureUsersTable } = require("../src/models/user.model");

ensureUsersTable()
  .then(() => {
    console.log("[db:ensure-users] Table `users` is ready.");
    process.exit(0);
  })
  .catch((err) => {
    console.error("[db:ensure-users] Failed:", err.message || err);
    process.exit(1);
  });
