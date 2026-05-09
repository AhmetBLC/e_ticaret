const favoriteModel = require("../models/favorite.model");
const asyncHandler = require("../middlewares/asyncHandler");

const toggleFavorite = asyncHandler(async (req, res) => {
  const { productId } = req.params;
  const result = await favoriteModel.toggleFavorite(req.user.id, productId);
  res.json({ success: true, data: result });
});

const getMyFavorites = asyncHandler(async (req, res) => {
  const data = await favoriteModel.findFavoritesByUser(req.user.id);
  res.json({ success: true, data });
});

module.exports = {
  toggleFavorite,
  getMyFavorites,
};
