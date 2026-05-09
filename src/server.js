const { port, nodeEnv, logLevel, logRequests, logRequestBodies } = require("./config/env");
const logger = require("./utils/logger");
const { runMigrations } = require("./utils/runMigrations");
const app = require("./app");

(async () => {
  try {
    await runMigrations();
  } catch (err) {
    logger.error("migrations_fatal", { message: err.message });
    // Don't exit — the app may still work if tables already exist
  }

  app.listen(port, () => {
    logger.info("server_start", {
      url: `http://localhost:${port}`,
      nodeEnv,
      logLevel,
      logRequests,
      logRequestBodies,
    });
  });
})();
