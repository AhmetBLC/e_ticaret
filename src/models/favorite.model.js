const { query } = require("../config/database");

async function toggleFavorite(userId, productId) {
  // Check if exists
  const existing = await query(
    "SELECT id FROM favorites WHERE user_id = $1 AND product_id = $2",
    [userId, productId]
  );

  if (existing.rows.length > 0) {
    // Remove
    await query(
      "DELETE FROM favorites WHERE user_id = $1 AND product_id = $2",
      [userId, productId]
    );
    return { favorited: false };
  } else {
    // Add
    await query(
      "INSERT INTO favorites (user_id, product_id) VALUES ($1, $2)",
      [userId, productId]
    );
    return { favorited: true };
  }
}

async function findFavoritesByUser(userId) {
  const result = await query(
    `SELECT p.*,
     (SELECT COUNT(*)::int FROM favorites WHERE product_id = p.id) as favorite_count
     FROM favorites f
     JOIN products p ON f.product_id = p.id
     WHERE f.user_id = $1
     ORDER BY f.created_at DESC`,
    [userId]
  );
  return result.rows;
}

async function isFavorited(userId, productId) {
  const result = await query(
    "SELECT 1 FROM favorites WHERE user_id = $1 AND product_id = $2",
    [userId, productId]
  );
  return result.rows.length > 0;
}

module.exports = {
  toggleFavorite,
  findFavoritesByUser,
  isFavorited,
};
