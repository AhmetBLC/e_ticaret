const { query } = require("../config/database");

const PAY_SELECT =
  "id, user_id, order_id, swap_id, amount, currency, status, payment_method, card_last_four, card_brand, provider_ref, three_ds_url, created_at, updated_at";

function run(client, text, params) {
  return client ? client.query(text, params) : query(text, params);
}

async function insertPayment(fields, client) {
  const r = await run(
    client,
    `INSERT INTO payments (user_id, order_id, swap_id, amount, currency, status, payment_method, card_last_four, card_brand, provider_ref, three_ds_url)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
     RETURNING ${PAY_SELECT}`,
    [
      fields.userId,
      fields.orderId || null,
      fields.swapId || null,
      fields.amount,
      fields.currency || "TRY",
      fields.status,
      fields.paymentMethod || "CARD",
      fields.cardLastFour || null,
      fields.cardBrand || null,
      fields.providerRef || null,
      fields.threeDsUrl || null,
    ]
  );
  return r.rows[0];
}

async function findPaymentById(id, client) {
  const r = await run(client, `SELECT ${PAY_SELECT} FROM payments WHERE id = $1`, [id]);
  return r.rows[0] || null;
}

async function findPaymentsByUser(userId, { limit = 20, offset = 0 } = {}) {
  const r = await query(
    `SELECT ${PAY_SELECT} FROM payments WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`,
    [userId, limit, offset]
  );
  return r.rows;
}

async function findPaymentsByOrderId(orderId) {
  const r = await query(
    `SELECT ${PAY_SELECT} FROM payments WHERE order_id = $1 ORDER BY created_at DESC`,
    [orderId]
  );
  return r.rows;
}

async function findPaymentBySwapId(swapId, client) {
  const r = await run(
    client,
    `SELECT ${PAY_SELECT} FROM payments WHERE swap_id = $1 ORDER BY created_at DESC LIMIT 1`,
    [swapId]
  );
  return r.rows[0] || null;
}

async function updatePaymentStatus(id, newStatus, client) {
  const r = await run(
    client,
    `UPDATE payments SET status = $2, updated_at = NOW() WHERE id = $1 RETURNING ${PAY_SELECT}`,
    [id, newStatus]
  );
  return r.rows[0] || null;
}

async function countPaymentsByUser(userId) {
  const r = await query("SELECT COUNT(*)::bigint AS c FROM payments WHERE user_id = $1", [userId]);
  return Number(r.rows[0].c);
}

module.exports = {
  insertPayment,
  findPaymentById,
  findPaymentsByUser,
  findPaymentsByOrderId,
  findPaymentBySwapId,
  updatePaymentStatus,
  countPaymentsByUser,
};
