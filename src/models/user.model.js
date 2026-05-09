const fs = require("fs");
const path = require("path");
const { query } = require("../config/database");

const USERS_MIGRATION_PATH = path.join(
  __dirname,
  "../../db/migrations/001_create_users.sql"
);

/**
 * Creates the `users` table if it does not exist (idempotent).
 * Uses the same DDL as `db/migrations/001_create_users.sql`.
 */
async function ensureUsersTable() {
  const sql = fs.readFileSync(USERS_MIGRATION_PATH, "utf8");
  await query(sql);
}

function normalizeEmail(email) {
  return String(email).trim().toLowerCase();
}

async function findUserById(id) {
  const result = await query(
    "SELECT id, email, created_at, role FROM users WHERE id = $1",
    [id]
  );
  return result.rows[0] || null;
}

async function findUserByEmail(email) {
  const normalized = normalizeEmail(email);
  const result = await query(
    "SELECT id, email, password_hash, created_at, role FROM users WHERE email = $1",
    [normalized]
  );
  return result.rows[0] || null;
}

async function createUser({ email, passwordHash }) {
  const normalized = normalizeEmail(email);
  const result = await query(
    `INSERT INTO users (email, password_hash)
     VALUES ($1, $2)
     RETURNING id, email, created_at, role`,
    [normalized, passwordHash]
  );
  return result.rows[0];
}

module.exports = {
  ensureUsersTable,
  findUserById,
  findUserByEmail,
  createUser,
};
