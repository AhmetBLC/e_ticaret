const checkoutService = require("../services/checkout.service");

async function checkout(req, res) {
  const userId = req.user ? req.user.id : null;
  const data = await checkoutService.checkout(userId, req.body);
  res.status(201).json({ success: true, data });
}

module.exports = { checkout };
