const AppError = require("../utils/AppError");
const { nodeEnv } = require("../config/env");
const logger = require("../utils/logger");

/**
 * Map common `pg` DatabaseError codes to stable API responses.
 * @param {Error & { code?: string }} err
 * @returns {{ status: number; code: string; message: string } | null}
 */
function mapDatabaseError(err) {
  if (!err || typeof err.code !== "string") {
    return null;
  }
  switch (err.code) {
    case "22P02":
      return {
        status: 400,
        code: "INVALID_INPUT",
        message: "Invalid identifier or data format",
      };
    case "23503":
      return {
        status: 400,
        code: "REFERENTIAL_INTEGRITY",
        message: "Related resource is missing or invalid",
      };
    case "23505":
      return {
        status: 409,
        code: "DUPLICATE",
        message: "A record with this data already exists",
      };
    default:
      return null;
  }
}

function errorHandler(err, req, res, next) {
  if (res.headersSent) {
    return next(err);
  }

  const path = req.originalUrl || req.url;
  const method = req.method;
  const userId = req.user && req.user.id ? req.user.id : undefined;

  if (err instanceof AppError) {
    const meta = {
      code: err.code,
      status: err.statusCode,
      message: err.message,
      method,
      path,
      userId,
    };
    if (err.statusCode >= 500) {
      logger.error("api_app_error", meta);
    } else {
      logger.warn("api_app_error", meta);
    }
    return res.status(err.statusCode).json({
      success: false,
      error: {
        code: err.code,
        message: err.message,
      },
    });
  }

  const db = mapDatabaseError(err);
  if (db) {
    logger.error("api_database_error", {
      pgCode: err.code,
      method,
      path,
      userId,
      clientCode: db.code,
      message: err.message,
      detail: nodeEnv !== "production" ? err.detail : undefined,
    });
    return res.status(db.status).json({
      success: false,
      error: {
        code: db.code,
        message: db.message,
      },
    });
  }

  logger.error("api_unhandled_error", {
    name: err.name,
    message: err.message,
    method,
    path,
    userId,
  });
  logger.errorWithStack("api_unhandled_error_stack", err);

  const message =
    nodeEnv === "production"
      ? "Internal Server Error"
      : err.message || "Internal Server Error";

  return res.status(500).json({
    success: false,
    error: {
      code: "INTERNAL_ERROR",
      message,
    },
  });
}

module.exports = errorHandler;
