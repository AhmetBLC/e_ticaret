const categoryService = require("../services/category.service");

async function list(req, res) {
  const flat = req.query.flat === "true" || req.query.flat === "1";
  const data = await categoryService.listCategories({ flat });
  res.json({ success: true, data });
}

async function create(req, res) {
  const data = await categoryService.createCategory(req.body);
  res.status(201).json({ success: true, data });
}

async function update(req, res) {
  const data = await categoryService.updateCategory(req.params.id, req.body);
  res.json({ success: true, data });
}

async function remove(req, res) {
  await categoryService.deleteCategory(req.params.id);
  res.json({
    success: true,
    data: { deleted: true, id: req.params.id },
  });
}

module.exports = {
  list,
  create,
  update,
  remove,
};
