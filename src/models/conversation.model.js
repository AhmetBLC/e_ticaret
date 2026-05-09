const { query } = require("../config/database");

const CONV_SELECT = "id, buyer_id, seller_id, product_id, created_at";

function run(client, text, params) {
  return client ? client.query(text, params) : query(text, params);
}

async function findConversationByParticipants(buyerId, sellerId, productId, client) {
  const r = await run(
    client,
    "SELECT " + CONV_SELECT + " FROM conversations WHERE buyer_id = $1 AND seller_id = $2 AND product_id = $3",
    [buyerId, sellerId, productId]
  );
  return r.rows[0] || null;
}

async function insertConversation({ buyerId, sellerId, productId }, client) {
  const r = await run(
    client,
    "INSERT INTO conversations (buyer_id, seller_id, product_id) VALUES ($1, $2, $3) RETURNING " + CONV_SELECT,
    [buyerId, sellerId, productId]
  );
  return r.rows[0];
}

async function findUserConversations(userId) {
  const r = await query(
    `SELECT c.*, 
            p.title as product_title, p.image_url as product_image,
            ub.email as buyer_email, us.email as seller_email
     FROM conversations c
     JOIN products p ON c.product_id = p.id
     JOIN users ub ON c.buyer_id = ub.id
     JOIN users us ON c.seller_id = us.id
     WHERE c.buyer_id = $1 OR c.seller_id = $1
     ORDER BY c.created_at DESC`,
    [userId]
  );
  return r.rows;
}

async function findConversationById(id) {
  const r = await query("SELECT " + CONV_SELECT + " FROM conversations WHERE id = $1", [id]);
  return r.rows[0] || null;
}

module.exports = {
  findConversationByParticipants,
  insertConversation,
  findUserConversations,
  findConversationById,
};
