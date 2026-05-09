const addressService = require("../services/address.service");

async function list(req, res) {
  const data = await addressService.listAddresses(req.user.id);
  res.json({ success: true, data });
}

async function get(req, res) {
  const data = await addressService.getAddress(req.user.id, req.params.id);
  res.json({ success: true, data });
}

async function create(req, res) {
  const data = await addressService.createAddress(req.user.id, req.body);
  res.status(201).json({ success: true, data });
}

async function update(req, res) {
  const data = await addressService.updateAddress(req.user.id, req.params.id, req.body);
  res.json({ success: true, data });
}

async function remove(req, res) {
  await addressService.deleteAddress(req.user.id, req.params.id);
  res.json({ success: true, data: { deleted: true } });
}

module.exports = { list, get, create, update, remove };
