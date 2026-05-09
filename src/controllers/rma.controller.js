const rmaService = require("../services/rma.service");
const rmaModel = require("../models/rma.model");

async function requestReturn(req, res) {
  const data = await rmaService.requestReturn(req.user.id, req.body);
  res.status(201).json({ success: true, data });
}

async function getMyReturns(req, res) {
  const data = await rmaModel.findReturnRequestsByUser(req.user.id);
  res.json({ success: true, data });
}

async function getAllReturns(req, res) {
  // Simple check for admin role can be added in routes
  const data = await rmaModel.findAllReturnRequests();
  res.json({ success: true, data });
}

async function updateStatus(req, res) {
  const data = await rmaService.handleReturnReview(req.params.id, req.body);
  res.json({ success: true, data });
}

module.exports = {
  requestReturn,
  getMyReturns,
  getAllReturns,
  updateStatus,
};
