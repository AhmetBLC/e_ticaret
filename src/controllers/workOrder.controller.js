const workOrderService = require("../services/workOrder.service");

async function list(req, res) {
  const data = await workOrderService.listWorkOrders(req.query);
  res.json({ success: true, data });
}

async function approve(req, res) {
  const data = await workOrderService.approveWorkOrder(req.params.id);
  res.json({ success: true, data });
}

async function reject(req, res) {
  const data = await workOrderService.rejectWorkOrder(req.params.id);
  res.json({ success: true, data });
}

module.exports = {
  list,
  approve,
  reject,
};
