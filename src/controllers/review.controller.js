const reviewService = require("../services/review.service");

async function addReview(req, res) {
  const data = await reviewService.addReview(req.user.id, req.params.productId, req.body);
  res.status(201).json({ success: true, data });
}

async function getProductReviews(req, res) {
  const data = await reviewService.getProductReviews(req.params.productId);
  res.json({ success: true, data });
}

module.exports = {
  addReview,
  getProductReviews,
};
