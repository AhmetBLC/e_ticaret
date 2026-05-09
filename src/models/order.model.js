const { query } = require("../config/database");

const ORDER_SELECT =
  "id, user_id, status, created_at, tracking_number, shipping_address_id, payment_id, total_amount, guest_tracking_code";

async function insertOrder({ userId, status, shippingAddressId, totalAmount, paymentId, guestTrackingCode }, client) {
  const r = await client.query(
    `INSERT INTO orders (user_id, status, shipping_address_id, total_amount, payment_id, guest_tracking_code)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING ${ORDER_SELECT}`,
    [userId || null, status, shippingAddressId || null, totalAmount || null, paymentId || null, guestTrackingCode || null]
  );
  return r.rows[0];
}

async function insertOrderItem(
  { orderId, productId, variantId, quantity, price },
  client
) {
  const r = await client.query(
    `INSERT INTO order_items (order_id, product_id, variant_id, quantity, price)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id, order_id, product_id, variant_id, quantity, price`,
    [orderId, productId, variantId, quantity, price]
  );
  return r.rows[0];
}

async function findOrderByIdAndUser(orderId, userId) {
  const r = await query(
    `SELECT ${ORDER_SELECT} FROM orders WHERE id = $1 AND user_id = $2`,
    [orderId, userId]
  );
  return r.rows[0] || null;
}

async function findOrderById(orderId, client) {
  const exec = client ? (text, params) => client.query(text, params) : query;
  const r = await exec(
    `SELECT o.*, 
            COALESCE(sh.tracking_number, o.tracking_number) AS tracking_number,
            sh.status AS cargo_status
     FROM orders o 
     LEFT JOIN shipments sh ON o.id = sh.order_id
     WHERE o.id = $1`,
    [orderId]
  );
  return r.rows[0] || null;
}

async function countOrdersByUser(userId) {
  const r = await query(
    "SELECT COUNT(*)::bigint AS c FROM orders WHERE user_id = $1",
    [userId]
  );
  return Number(r.rows[0].c);
}

async function findOrdersByUserPaginated({ userId, limit, offset }) {
  const r = await query(
    `SELECT o.*, 
            COALESCE(sh.tracking_number, o.tracking_number) AS tracking_number,
            sh.status AS cargo_status
     FROM orders o
     LEFT JOIN shipments sh ON o.id = sh.order_id
     WHERE o.user_id = $1
     ORDER BY o.created_at DESC
     LIMIT $2 OFFSET $3`,
    [userId, limit, offset]
  );
  return r.rows;
}

async function findOrderItemsByOrderIds(orderIds) {
  if (!orderIds.length) {
    return [];
  }
  const r = await query(
    `SELECT id, order_id, product_id, variant_id, quantity, price
     FROM order_items
     WHERE order_id = ANY($1::uuid[])
     ORDER BY order_id, id`,
    [orderIds]
  );
  return r.rows;
}

/**
 * @param {object} [client] — pg client or omit for pool
 */
async function updateOrderFields(orderId, fields, client) {
  const allowed = ["status", "tracking_number", "guest_tracking_code", "total_amount"];
  const exec = client ? (text, params) => client.query(text, params) : query;
  const sets = [];
  const vals = [];
  let i = 1;
  for (const key of allowed) {
    if (Object.prototype.hasOwnProperty.call(fields, key)) {
      sets.push(`${key} = $${i++}`);
      vals.push(fields[key]);
    }
  }
  if (sets.length === 0) {
    return null;
  }
  vals.push(orderId);
  const sql = `
    UPDATE orders
    SET ${sets.join(", ")}
    WHERE id = $${i}
    RETURNING ${ORDER_SELECT}
  `;
  const r = await exec(sql, vals);
  return r.rows[0] || null;
}

async function findOrdersByIds(ids) {
  if (!ids.length) return [];
  const r = await query(
    `SELECT ${ORDER_SELECT} FROM orders WHERE id = ANY($1::uuid[])`,
    [ids]
  );
  return r.rows;
}

async function findOrderByGuestCode(code) {
  const r = await query(
    `SELECT ${ORDER_SELECT} FROM orders WHERE guest_tracking_code = $1`,
    [code]
  );
  return r.rows[0] || null;
}

module.exports = {
  insertOrder,
  insertOrderItem,
  findOrderByIdAndUser,
  findOrderById,
  countOrdersByUser,
  findOrdersByUserPaginated,
  findOrderItemsByOrderIds,
  updateOrderFields,
  findOrdersByIds,
  findOrderByGuestCode,
};
