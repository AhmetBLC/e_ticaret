const { port, nodeEnv, logLevel, logRequests, logRequestBodies } = require("./config/env");
const logger = require("./utils/logger");
const { runMigrations } = require("./utils/runMigrations");
const { testConnection } = require("./config/database");
const app = require("./app");

(async () => {
  try {
    const { now, db } = await testConnection();
    logger.info("db_connected", { database: db, serverTime: now });
    await runMigrations();
  } catch (err) {
    logger.error("db_init_error", { message: err.message, stack: err.stack });
    // Don't exit — the app may still work if tables already exist, 
    // but log the error clearly for AWS debugging.
  }

  const host = "0.0.0.0";
  app.listen(port, host, () => {
    logger.info("server_start", {
      url: `http://${host}:${port}`,
      nodeEnv,
      logLevel,
      logRequests,
      logRequestBodies,
    });
  });
})();
