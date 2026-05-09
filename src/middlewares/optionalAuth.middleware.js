const jwt = require("jsonwebtoken");
const { jwtSecret } = require("../config/env");

/**
 * Attaches req.user if a valid token is present, but doesn't block if missing.
 */
function optionalAuthenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return next();
  }

  const token = authHeader.split(" ")[1];
  try {
    const decoded = jwt.verify(token, jwtSecret);
    req.user = { id: decoded.sub || decoded.id };
    next();
  } catch (err) {
    // If token is invalid, we ignore it for optional auth
    next();
  }
}

module.exports = { optionalAuthenticate };
