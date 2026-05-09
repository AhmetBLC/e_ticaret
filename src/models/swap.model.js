const { query } = require("../config/database");

const SWAP_SELECT = "id, requester_user_id, receiver_user_id, product_offered_id, product_requested_id, status, created_at";

const SWAP_JOIN = "LEFT JOIN shipments sh ON s.id = sh.swap_id";
const SWAP_SELECT_WITH_TRACKING = `
  s.id, s.requester_user_id, s.receiver_user_id, s.product_offered_id, s.product_requested_id, s.status, s.created_at,
  sh.tracking_number, sh.status AS cargo_status
`;

async function insertSwap(
  {
    requesterUserId,
    receiverUserId,
    productOfferedId,
    productRequestedId,
    status,
  },
  client
) {
  const run = client ? (t, p) => client.query(t, p) : query;
  const r = await run(
    `INSERT INTO swaps (
       requester_user_id,
       receiver_user_id,
       product_offered_id,
       product_requested_id,
       status
     )
     VALUES ($1, $2, $3, $4, $5)
     RETURNING ${SWAP_SELECT}`,
    [
      requesterUserId,
      receiverUserId,
      productOfferedId,
      productRequestedId,
      status,
    ]
  );
  return r.rows[0];
}

async function findSwapById(id) {
  const r = await query(
    `SELECT s.*, sh.tracking_number, sh.status AS cargo_status
     FROM swaps s
     LEFT JOIN LATERAL (
       SELECT tracking_number, status
       FROM shipments
       WHERE swap_id = s.id
       ORDER BY created_at DESC
       LIMIT 1
     ) sh ON true
     WHERE s.id = $1`,
    [id]
  );
  return r.rows[0] || null;
}

async function countSwapsForUser(userId, status) {
  const params = [userId];
  let where = "(requester_user_id = $1 OR receiver_user_id = $1)";
  if (status) {
    params.push(status);
    where += " AND status = $2";
  }
  const r = await query(
    `SELECT COUNT(*)::bigint AS c FROM swaps WHERE ${where}`,
    params
  );
  return Number(r.rows[0].c);
}

async function findSwapsForUserPaginated({ userId, status, limit, offset }) {
  const params = [userId];
  let where = "(s.requester_user_id = $1 OR s.receiver_user_id = $1)";
  if (status) {
    params.push(status);
    where += " AND s.status = $2";
  }
  const limitIdx = params.length + 1;
  const offsetIdx = params.length + 2;
  params.push(limit, offset);
  const r = await query(
    `SELECT s.*, sh.tracking_number, sh.status AS cargo_status
     FROM swaps s
     LEFT JOIN LATERAL (
       SELECT tracking_number, status
       FROM shipments
       WHERE swap_id = s.id
       AND (sender_user_id = $1 OR receiver_user_id = $1)
       ORDER BY (sender_user_id = $1) DESC, created_at DESC
       LIMIT 1
     ) sh ON true
     WHERE ${where}
     ORDER BY s.created_at DESC
     LIMIT $${limitIdx} OFFSET $${offsetIdx}`,
    params
  );
  return r.rows;
}

async function findSwapsByIds(ids) {
  if (!ids.length) {
    return new Map();
  }
  const r = await query(
    `SELECT ${SWAP_SELECT} FROM swaps WHERE id = ANY($1::uuid[])`,
    [ids]
  );
  const map = new Map();
  for (const row of r.rows) {
    map.set(row.id, row);
  }
  return map;
}

async function findSwapByIdForUpdate(id, client) {
  const r = await client.query(
    `SELECT ${SWAP_SELECT} FROM swaps WHERE id = $1 FOR UPDATE`,
    [id]
  );
  return r.rows[0] || null;
}

async function updateSwapStatus(id, status, client) {
  const run = client ? (t, p) => client.query(t, p) : query;
  const r = await run(
    `UPDATE swaps
     SET status = $2
     WHERE id = $1 AND status = 'PENDING'
     RETURNING ${SWAP_SELECT}`,
    [id, status]
  );
  return r.rows[0] || null;
}

async function updateSwapStatusFromWorkshop(id, newStatus, client) {
  const run = client ? (t, p) => client.query(t, p) : query;
  const r = await run(
    `UPDATE swaps
     SET status = $2
     WHERE id = $1 AND status = 'WORKSHOP'
     RETURNING ${SWAP_SELECT}`,
    [id, newStatus]
  );
  return r.rows[0] || null;
}

module.exports = {
  insertSwap,
  findSwapById,
  countSwapsForUser,
  findSwapsForUserPaginated,
  findSwapsByIds,
  findSwapByIdForUpdate,
  updateSwapStatus,
  updateSwapStatusFromWorkshop,
};
