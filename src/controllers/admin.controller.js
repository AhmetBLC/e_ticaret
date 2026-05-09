const adminService = require("../services/admin.service");

async function dashboard(req, res) {
  const data = await adminService.getDashboardStats();
  res.json({ success: true, data });
}

async function listUsers(req, res) {
  const data = await adminService.listAllUsers(req.query);
  res.json({ success: true, data });
}

async function listSwaps(req, res) {
  const data = await adminService.listAllSwaps(req.query);
  res.json({ success: true, data });
}

async function listProducts(req, res) {
  const data = await adminService.listAllProducts(req.query);
  res.json({ success: true, data });
}

async function listOrders(req, res) {
  const data = await adminService.listAllOrders(req.query);
  res.json({ success: true, data });
}

module.exports = {
  dashboard,
  listUsers,
  listSwaps,
  listProducts,
  listOrders,
};
