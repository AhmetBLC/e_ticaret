const productService = require("../services/product.service");

async function list(req, res) {
  const data = await productService.listProducts(req.query);
  res.json({ success: true, data });
}

async function listMine(req, res) {
  const data = await productService.listMyProducts(req.user.id, req.query);
  res.json({ success: true, data });
}

async function getById(req, res) {
  const data = await productService.getProductById(req.params.id);
  res.json({ success: true, data });
}

async function create(req, res) {
  const data = await productService.createProduct(req.user.id, req.body);
  res.status(201).json({ success: true, data });
}

async function update(req, res) {
  const data = await productService.updateProduct(
    req.params.id,
    req.user.id,
    req.body
  );
  res.json({ success: true, data });
}

async function remove(req, res) {
  await productService.deleteProduct(req.params.id, req.user.id);
  res.json({
    success: true,
    data: { deleted: true, id: req.params.id },
  });
}

module.exports = {
  list,
  listMine,
  getById,
  create,
  update,
  remove,
};
