const path = require("path");
const dotenv = require("dotenv");

dotenv.config({ path: path.resolve(process.cwd(), ".env") });

function getPort() {
  const port = parseInt(process.env.PORT, 10);
  return Number.isFinite(port) && port > 0 ? port : 3000;
}

function getBcryptRounds() {
  const n = parseInt(process.env.BCRYPT_ROUNDS, 10);
  return Number.isFinite(n) && n >= 10 && n <= 15 ? n : 12;
}

function getLogLevel() {
  const raw = (process.env.LOG_LEVEL || "").trim().toLowerCase();
  const allowed = ["debug", "info", "warn", "error", "silent"];
  if (allowed.includes(raw)) {
    return raw;
  }
  const env = process.env.NODE_ENV || "development";
  return env === "production" ? "info" : "debug";
}

function getLogRequestsEnabled() {
  const v = (process.env.LOG_REQUESTS || "").trim().toLowerCase();
  if (v === "0" || v === "false" || v === "no") {
    return false;
  }
  return true;
}

function getLogRequestBodiesEnabled() {
  const v = (process.env.LOG_REQUEST_BODY || "").trim().toLowerCase();
  return v === "1" || v === "true" || v === "yes";
}

function getDatabaseSslOption() {
  const raw = process.env.DATABASE_SSL || process.env.DB_SSL || "";
  const enabled = raw === "true" || raw === "1";
  return enabled ? { rejectUnauthorized: false } : false;
}

/** Pool options for `pg` (see `.env.example`). Returns `null` if not configured. */
function getDatabasePoolConfig() {
  const ssl = getDatabaseSslOption();
  const url = (process.env.DATABASE_URL || "").trim();
  if (url) {
    return { connectionString: url, ssl };
  }
  const user = process.env.PGUSER;
  const database = process.env.PGDATABASE;
  if (!user || !database) {
    return null;
  }
  const port = parseInt(process.env.PGPORT || "5432", 10);
  return {
    host: process.env.PGHOST || "localhost",
    port: Number.isFinite(port) && port > 0 ? port : 5432,
    user,
    password: process.env.PGPASSWORD ?? "",
    database,
    ssl,
  };
}

module.exports = {
  port: getPort(),
  nodeEnv: process.env.NODE_ENV || "development",
  logLevel: getLogLevel(),
  logRequests: getLogRequestsEnabled(),
  logRequestBodies: getLogRequestBodiesEnabled(),
  databaseUrl: process.env.DATABASE_URL || "",
  databaseSsl:
    process.env.DATABASE_SSL === "true" || process.env.DATABASE_SSL === "1",
  getDatabasePoolConfig,
  jwtSecret: process.env.JWT_SECRET || "",
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || "7d",
  bcryptRounds: getBcryptRounds(),
  corsOrigin: process.env.CORS_ORIGIN || "*",
};
