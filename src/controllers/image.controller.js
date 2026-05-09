const productModel = require("../models/product.model");

async function addImage(req, res) {
  const { url, sortOrder } = req.body;
  const data = await productModel.addProductImage(req.params.productId, url, sortOrder);
  res.status(201).json({ success: true, data });
}

async function getImages(req, res) {
  const data = await productModel.getProductImages(req.params.productId);
  res.json({ success: true, data });
}

async function deleteImage(req, res) {
  await productModel.deleteProductImage(req.params.imageId);
  res.json({ success: true, message: "Resim silindi." });
}

module.exports = {
  addImage,
  getImages,
  deleteImage,
};
