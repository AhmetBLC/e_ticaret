const { query } = require("../config/database");

async function findReviewsByProduct(productId) {
  const r = await query(
    `SELECT pr.*, u.email as user_name 
     FROM product_reviews pr
     JOIN users u ON pr.user_id = u.id
     WHERE pr.product_id = $1 
     ORDER BY pr.created_at DESC`,
    [productId]
  );
  return r.rows;
}

async function insertReview({ productId, userId, rating, comment }) {
  const r = await query(
    `INSERT INTO product_reviews (product_id, user_id, rating, comment)
     VALUES ($1, $2, $3, $4)
     RETURNING id, product_id, user_id, rating, comment, created_at`,
    [productId, userId, rating, comment]
  );
  return r.rows[0];
}

async function getAverageRating(productId) {
  const r = await query(
    "SELECT AVG(rating)::float as avg_rating, COUNT(*)::int as review_count FROM product_reviews WHERE product_id = $1",
    [productId]
  );
  return r.rows[0];
}

module.exports = {
  findReviewsByProduct,
  insertReview,
  getAverageRating,
};
