const { query } = require("../config/database");

const RMA_SELECT = "id, order_id, user_id, reason, status, image_url, admin_notes, created_at";

async function insertReturnRequest({ orderId, userId, reason, imageUrl }) {
  const r = await query(
    `INSERT INTO return_requests (order_id, user_id, reason, image_url)
     VALUES ($1, $2, $3, $4)
     RETURNING ${RMA_SELECT}`,
    [orderId, userId, reason, imageUrl]
  );
  return r.rows[0];
}

async function findReturnRequestsByUser(userId) {
  const r = await query(
    `SELECT ${RMA_SELECT} FROM return_requests WHERE user_id = $1 ORDER BY created_at DESC`,
    [userId]
  );
  return r.rows;
}

async function findAllReturnRequests() {
  const r = await query(
    `SELECT rr.*, u.full_name as user_name, o.id as order_display_id 
     FROM return_requests rr
     JOIN users u ON rr.user_id = u.id
     JOIN orders o ON rr.order_id = o.id
     ORDER BY rr.created_at DESC`
  );
  return r.rows;
}

async function updateReturnRequestStatus(id, status, adminNotes) {
  const r = await query(
    `UPDATE return_requests 
     SET status = $1, admin_notes = $2
     WHERE id = $3
     RETURNING ${RMA_SELECT}`,
    [status, adminNotes || null, id]
  );
  return r.rows[0] || null;
}

module.exports = {
  insertReturnRequest,
  findReturnRequestsByUser,
  findAllReturnRequests,
  updateReturnRequestStatus,
};
