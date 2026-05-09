/**
 * Set a user's role (e.g. promote to admin for workshop approval).
 * Usage: node scripts/set-user-role.js <email> [role]
 * Example: node scripts/set-user-role.js admin@example.com admin
 */
require("../src/config/env");
const { query } = require("../src/config/database");

const email = process.argv[2];
const role = (process.argv[3] || "admin").trim().toLowerCase();

if (!email) {
  console.error("Usage: node scripts/set-user-role.js <email> [role]");
  process.exit(1);
}

const allowed = new Set(["user", "admin"]);
if (!allowed.has(role)) {
  console.error('role must be "user" or "admin"');
  process.exit(1);
}

query("UPDATE users SET role = $1 WHERE LOWER(email) = LOWER($2)", [role, email])
  .then((r) => {
    if (r.rowCount === 0) {
      console.error(`No user found with email: ${email}`);
      process.exit(1);
    }
    console.log(`Updated ${email} → role "${role}".`);
    process.exit(0);
  })
  .catch((err) => {
    console.error(err.message || err);
    process.exit(1);
  });
