-- Users table (run manually or via ensureUsersTable() in src/models/user.model.js)
-- Requires PostgreSQL 13+ for gen_random_uuid() without extensions.

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
