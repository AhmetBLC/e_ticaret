const jwt = require("jsonwebtoken");
const { ROLES } = require("../constants/roles");
const { jwtSecret } = require("../config/env");
const AppError = require("../utils/AppError");
const asyncHandler = require("./asyncHandler");
const userModel = require("../models/user.model");

function extractBearerToken(req) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith("Bearer ")) {
    return null;
  }
  return header.slice(7).trim();
}

/**
 * Optional: validates Bearer JWT when present and attaches `req.user` with `{ id, role }` from claims only (no DB).
 */
function optionalAuth(req, res, next) {
  const token = extractBearerToken(req);
  if (!token) {
    return next();
  }
  if (!jwtSecret) {
    return next();
  }
  try {
    const payload = jwt.verify(token, jwtSecret);
    req.user = {
      id: payload.sub,
      role: payload.role || ROLES.USER,
    };
  } catch {
    // Invalid token: continue as anonymous
  }
  next();
}

/**
 * Protected routes: reads `Authorization: Bearer <token>`, verifies JWT, loads user from DB, sets `req.user`:
 * `{ id, email, created_at, role }`.
 */
const authenticate = asyncHandler(async (req, res, next) => {
  const token = extractBearerToken(req);
  if (!token) {
    throw new AppError(
      "Authentication required. Send a Bearer token in the Authorization header.",
      401,
      "UNAUTHORIZED"
    );
  }
  if (!jwtSecret) {
    throw new AppError("Server misconfiguration", 500, "CONFIG_ERROR");
  }

  let payload;
  try {
    payload = jwt.verify(token, jwtSecret);
  } catch (err) {
    if (err.name === "JsonWebTokenError" || err.name === "TokenExpiredError") {
      throw new AppError("Invalid or expired token", 401, "UNAUTHORIZED");
    }
    throw err;
  }

  const user = await userModel.findUserById(payload.sub);
  if (!user) {
    throw new AppError("Invalid or expired token", 401, "UNAUTHORIZED");
  }

  req.user = {
    id: user.id,
    email: user.email,
    created_at: user.created_at,
    role: user.role || ROLES.USER,
  };
  next();
});

function requireRole(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return next(
        new AppError("Authentication required", 401, "UNAUTHORIZED")
      );
    }
    if (!allowedRoles.includes(req.user.role)) {
      return next(new AppError("Forbidden", 403, "FORBIDDEN"));
    }
    next();
  };
}

module.exports = {
  extractBearerToken,
  optionalAuth,
  authenticate,
  requireAuth: authenticate,
  requireRole,
};
