const jwt = require("jsonwebtoken");
const { jwtSecret, jwtExpiresIn } = require("../config/env");
const { ROLES } = require("../constants/roles");
const AppError = require("./AppError");

function signAccessToken(userId, role = ROLES.USER) {
  if (!jwtSecret) {
    throw new AppError(
      "JWT is not configured. Set JWT_SECRET in .env",
      500,
      "CONFIG_ERROR"
    );
  }
  return jwt.sign({ sub: userId, role }, jwtSecret, {
    expiresIn: jwtExpiresIn,
  });
}

module.exports = {
  signAccessToken,
};
