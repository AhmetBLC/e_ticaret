const logger = require("../utils/logger");
const { logRequests, logRequestBodies } = require("../config/env");

const SENSITIVE_KEYS = new Set([
  "password",
  "currentpassword",
  "newpassword",
  "token",
  "accesstoken",
  "refreshtoken",
  "secret",
  "authorization",
]);

/**
 * @param {unknown} body
 * @param {number} depth
 * @returns {unknown}
 */
function sanitizeBody(body, depth = 0) {
  if (depth > 4) {
    return "[MAX_DEPTH]";
  }
  if (body == null) {
    return body;
  }
  if (Array.isArray(body)) {
    return body.slice(0, 30).map((x) => sanitizeBody(x, depth + 1));
  }
  if (typeof body !== "object") {
    return body;
  }
  const out = {};
  for (const [k, v] of Object.entries(body)) {
    const low = k.toLowerCase();
    if (SENSITIVE_KEYS.has(low)) {
      out[k] = "[REDACTED]";
    } else if (typeof v === "object" && v !== null) {
      out[k] = sanitizeBody(v, depth + 1);
    } else {
      out[k] = v;
    }
  }
  return out;
}

/**
 * Logs each API request when it finishes (method, path, status, duration).
 * Optional debug log of JSON body (sanitized) when LOG_REQUEST_BODY=true.
 */
function requestLogger(req, res, next) {
  if (!logRequests) {
    return next();
  }

  const start = Date.now();
  const fullPath = req.originalUrl || req.url;

  res.on("finish", () => {
    const ms = Date.now() - start;
    const pathOnly = fullPath.split("?")[0];
    /** @type {Record<string, unknown>} */
    const meta = {
      method: req.method,
      path: pathOnly,
      status: res.statusCode,
      ms,
    };
    if (req.user && req.user.id) {
      meta.userId = req.user.id;
    }

    if (res.statusCode >= 500) {
      logger.error("http_request", meta);
    } else if (res.statusCode >= 400) {
      logger.warn("http_request", meta);
    } else {
      logger.info("http_request", meta);
    }

    if (
      logRequestBodies &&
      req.body &&
      typeof req.body === "object" &&
      Object.keys(req.body).length > 0
    ) {
      logger.debug("http_request_body", {
        path: pathOnly,
        method: req.method,
        body: sanitizeBody(req.body),
      });
    }
  });

  next();
}

module.exports = { requestLogger, sanitizeBody };
