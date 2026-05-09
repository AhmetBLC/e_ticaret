const { query } = require("../config/database");

const SHIP_SELECT = `
  s.id, s.order_id, s.swap_id, s.sender_user_id, s.receiver_user_id, 
  s.sender_address_id, s.receiver_address_id, s.tracking_number, 
  s.barcode, s.carrier, s.status, s.estimated_delivery, 
  s.weight_kg, s.created_at, s.updated_at,
  u_sender.email as sender_name,
  u_receiver.email as receiver_name,
  COALESCE(p_swap.title, p_order.title, 'Çoklu Ürün') as product_title
`;

const SHIP_JOIN = `
  LEFT JOIN users u_sender ON s.sender_user_id = u_sender.id
  LEFT JOIN users u_receiver ON s.receiver_user_id = u_receiver.id
  LEFT JOIN swaps sw ON s.swap_id = sw.id
  LEFT JOIN products p_swap ON sw.product_requested_id = p_swap.id
  LEFT JOIN orders o ON s.order_id = o.id
  LEFT JOIN order_items oi ON o.id = oi.order_id
  LEFT JOIN products p_order ON oi.product_id = p_order.id
`;

function run(client, text, params) {
  return client ? client.query(text, params) : query(text, params);
}

async function insertShipment(fields, client) {
  const r = await run(
    client,
    `INSERT INTO shipments (order_id, swap_id, sender_user_id, receiver_user_id, sender_address_id, receiver_address_id, tracking_number, barcode, carrier, status, estimated_delivery, weight_kg)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
     RETURNING id`,
    [
      fields.orderId || null,
      fields.swapId || null,
      fields.senderUserId,
      fields.receiverUserId,
      fields.senderAddressId || null,
      fields.receiverAddressId || null,
      fields.trackingNumber,
      fields.barcode || null,
      fields.carrier || "SimKargo",
      fields.status,
      fields.estimatedDelivery || null,
      fields.weightKg || null,
    ]
  );
  return findShipmentById(r.rows[0].id);
}

async function findShipmentById(id) {
  const r = await query(
    `SELECT ${SHIP_SELECT} FROM shipments s ${SHIP_JOIN} WHERE s.id = $1`,
    [id]
  );
  return r.rows[0] || null;
}

async function findShipmentByTracking(trackingNumber) {
  const r = await query(
    `SELECT ${SHIP_SELECT} FROM shipments s ${SHIP_JOIN} WHERE s.tracking_number = $1`,
    [trackingNumber]
  );
  return r.rows[0] || null;
}

async function findShipmentsByOrderId(orderId) {
  const r = await query(
    `SELECT ${SHIP_SELECT} FROM shipments s ${SHIP_JOIN} WHERE s.order_id = $1 ORDER BY s.created_at DESC`,
    [orderId]
  );
  return r.rows;
}

async function findAllShipments({ limit = 50, offset = 0 } = {}) {
  const r = await query(
    `SELECT ${SHIP_SELECT} FROM shipments s ${SHIP_JOIN}
     GROUP BY s.id, u_sender.email, u_receiver.email, p_swap.title, p_order.title
     ORDER BY s.created_at DESC LIMIT $1 OFFSET $2`,
    [limit, offset]
  );
  return r.rows;
}

async function updateShipmentStatus(id, newStatus, client) {
  await run(
    client,
    `UPDATE shipments SET status = $2, updated_at = NOW() WHERE id = $1`,
    [id, newStatus]
  );
  return findShipmentById(id);
}

async function findShipmentsBySwapId(swapId) {
  const r = await query(
    `SELECT ${SHIP_SELECT} FROM shipments s ${SHIP_JOIN} WHERE s.swap_id = $1 ORDER BY s.created_at DESC`,
    [swapId]
  );
  return r.rows;
}

async function findShipmentsByUser(userId, { limit = 20, offset = 0 } = {}) {
  const r = await query(
    `SELECT ${SHIP_SELECT} FROM shipments s ${SHIP_JOIN}
     WHERE s.sender_user_id = $1 OR s.receiver_user_id = $1
     GROUP BY s.id, u_sender.name, u_receiver.name, p_swap.title, p_order.title
     ORDER BY s.created_at DESC LIMIT $2 OFFSET $3`,
    [userId, limit, offset]
  );
  return r.rows;
}

module.exports = {
  insertShipment,
  findShipmentById,
  findShipmentByTracking,
  findShipmentsByOrderId,
  findShipmentsBySwapId,
  findShipmentsByUser,
  findAllShipments,
  updateShipmentStatus,
};
