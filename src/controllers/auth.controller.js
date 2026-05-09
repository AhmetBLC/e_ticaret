const authService = require("../services/auth.service");

async function register(req, res) {
  const { email, password } = req.body;
  const data = await authService.register({ email, password });
  res.status(201).json({
    success: true,
    data,
  });
}

async function login(req, res) {
  const { email, password } = req.body;
  const data = await authService.login({ email, password });
  res.json({
    success: true,
    data,
  });
}

module.exports = {
  register,
  login,
};
