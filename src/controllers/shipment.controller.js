const shipmentService = require("../services/shipment.service");

async function track(req, res) {
  const data = await shipmentService.trackShipment(req.params.trackingNumber);
  res.json({ success: true, data });
}

async function getById(req, res) {
  const data = await shipmentService.getShipmentById(req.params.id);
  res.json({ success: true, data });
}

async function myShipments(req, res) {
  const page = Number(req.query.page) || 1;
  const limit = Number(req.query.limit) || 20;
  const data = await shipmentService.getMyShipments(req.user.id, page, limit);
  res.json({ success: true, data });
}

async function listAll(req, res) {
  const page = Number(req.query.page) || 1;
  const limit = Number(req.query.limit) || 50;
  const data = await shipmentService.listAllShipments(page, limit);
  res.json({ success: true, data });
}

async function advanceStatus(req, res) {
  const shipment = await shipmentService.advanceShipmentStatus(
    req.params.id,
    req.body.status
  );
  res.json({ success: true, data: { shipment } });
}

async function simulateDelivery(req, res) {
  const data = await shipmentService.simulateDelivery(req.params.id);
  res.json({ success: true, data });
}

async function initiate(req, res) {
  const data = await shipmentService.initiateShipmentForWorkOrder(req.params.workOrderId);
  res.json({ success: true, data });
}

module.exports = {
  track,
  getById,
  myShipments,
  listAll,
  advanceStatus,
  simulateDelivery,
  initiate,
};
