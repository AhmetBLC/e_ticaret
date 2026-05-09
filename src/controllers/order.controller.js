const orderService = require("../services/order.service");

async function create(req, res) {
  const data = await orderService.createOrder(req.user.id, req.body);
  res.status(201).json({ success: true, data });
}

async function list(req, res) {
  const data = await orderService.listOrders(req.user.id, req.query);
  res.json({ success: true, data });
}

async function advanceStatus(req, res) {
  const data = await orderService.advanceOrderStatus(
    req.user.id,
    req.params.id,
    req.body.status
  );
  res.json({ success: true, data });
}

async function getStats(req, res) {
  const data = await orderService.getStats(req.user.id, req.user.role);
  res.json({ success: true, data });
}

module.exports = {
  create,
  list,
  advanceStatus,
  getStats,
};
