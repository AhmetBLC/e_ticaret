const bcrypt = require("bcryptjs");
const { bcryptRounds } = require("../config/env");
const AppError = require("../utils/AppError");
const { signAccessToken } = require("../utils/jwt");
const { ROLES } = require("../constants/roles");
const userModel = require("../models/user.model");

async function register({ email, password }) {
  const existing = await userModel.findUserByEmail(email);
  if (existing) {
    throw new AppError(
      "An account with this email already exists",
      409,
      "EMAIL_TAKEN"
    );
  }

  const passwordHash = await bcrypt.hash(password, bcryptRounds);

  try {
    const user = await userModel.createUser({ email, passwordHash });
    return {
      user: {
        id: user.id,
        email: user.email,
        created_at: user.created_at,
        role: user.role || ROLES.USER,
      },
    };
  } catch (err) {
    if (err.code === "23505") {
      throw new AppError(
        "An account with this email already exists",
        409,
        "EMAIL_TAKEN"
      );
    }
    throw err;
  }
}

async function login({ email, password }) {
  const user = await userModel.findUserByEmail(email);
  if (!user) {
    throw new AppError(
      "Invalid email or password",
      401,
      "INVALID_CREDENTIALS"
    );
  }

  const match = await bcrypt.compare(password, user.password_hash);
  if (!match) {
    throw new AppError(
      "Invalid email or password",
      401,
      "INVALID_CREDENTIALS"
    );
  }

  const role = user.role || ROLES.USER;
  const token = signAccessToken(user.id, role);

  return {
    token,
    user: {
      id: user.id,
      email: user.email,
      created_at: user.created_at,
      role,
    },
  };
}

module.exports = {
  register,
  login,
};
