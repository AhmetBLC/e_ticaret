const swapService = require("../services/swap.service");

async function list(req, res) {
  const data = await swapService.listSwapsForUser(req.user.id, req.query);
  res.json({ success: true, data });
}

async function create(req, res) {
  const data = await swapService.createSwap(req.user.id, req.body);
  res.status(201).json({ success: true, data });
}

async function accept(req, res) {
  const data = await swapService.acceptSwap(req.params.id, req.user.id, req.body);
  res.json({ success: true, data });
}

async function reject(req, res) {
  const data = await swapService.rejectSwap(req.params.id, req.user.id);
  res.json({ success: true, data });
}

module.exports = {
  list,
  create,
  accept,
  reject,
};
