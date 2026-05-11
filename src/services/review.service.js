const reviewModel = require("../models/review.model");
const productModel = require("../models/product.model");
const AppError = require("../utils/AppError");

async function addReview(userId, productId, { rating, comment }) {
  const p = await productModel.findProductById(productId);
  if (!p) {
    throw new AppError("Ürün bulunamadı.", 404, "PRODUCT_NOT_FOUND");
  }

  // Optional: Check if user actually bought the product
  // For MVP, we'll allow any authenticated user to review (social proof)
  
  return await reviewModel.insertReview({
    productId,
    userId,
    rating,
    comment
  });
}

async function getProductReviews(productId) {
  const reviews = await reviewModel.findReviewsByProduct(productId);
  const stats = await reviewModel.getAverageRating(productId);
  
  return {
    reviews,
    averageRating: stats.avg_rating || 0,
    reviewCount: stats.review_count || 0
  };
}

module.exports = {
  addReview,
  getProductReviews,
};
