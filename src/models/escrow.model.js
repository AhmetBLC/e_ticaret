const { query } = require("../config/database");

const ESCROW_SELECT = "id, swap_id, order_id, amount, status, created_at";

function run(client, text, params) {
  return client ? client.query(text, params) : query(text, params);
}

async function insertEscrow({ swapId, orderId, amount, status }, client) {
  const r = await run(
    client,
    `INSERT INTO escrows (swap_id, order_id, amount, status)
     VALUES ($1, $2, $3, $4)
     RETURNING ${ESCROW_SELECT}`,
    [swapId || null, orderId || null, amount, status]
  );
  return r.rows[0];
}

async function findEscrowBySwapId(swapId) {
  const r = await query(
    `SELECT ${ESCROW_SELECT} FROM escrows WHERE swap_id = $1`,
    [swapId]
  );
  return r.rows[0] || null;
}

/**
 * @returns {Map<string, object>} swap_id → row
 */
async function findEscrowsBySwapIds(swapIds) {
  if (!swapIds.length) {
    return new Map();
  }
  const r = await query(
    `SELECT ${ESCROW_SELECT} FROM escrows WHERE swap_id = ANY($1::uuid[])`,
    [swapIds]
  );
  const map = new Map();
  for (const row of r.rows) {
    map.set(row.swap_id, row);
  }
  return map;
}

/**
 * HELD → RELEASED when workshop approves (price difference settled).
 */
async function releaseEscrowBySwapId(swapId, client) {
  const r = await run(
    client,
    `UPDATE escrows
     SET status = 'RELEASED'
     WHERE swap_id = $1 AND status = 'HELD'
     RETURNING ${ESCROW_SELECT}`,
    [swapId]
  );
  return r.rows[0] || null;
}

/**
 * HELD → REFUNDED when workshop rejects (swap cancelled, hold lifted).
 */
async function refundEscrowBySwapId(swapId, client) {
  const r = await run(
    client,
    `UPDATE escrows
     SET status = 'REFUNDED'
     WHERE swap_id = $1 AND status = 'HELD'
     RETURNING ${ESCROW_SELECT}`,
    [swapId]
  );
  return r.rows[0] || null;
}

async function findEscrowsByOrderIds(orderIds) {
  if (!orderIds.length) return new Map();
  const r = await query(
    `SELECT ${ESCROW_SELECT} FROM escrows WHERE order_id = ANY($1::uuid[])`,
    [orderIds]
  );
  const map = new Map();
  for (const row of r.rows) {
    map.set(row.order_id, row);
  }
  return map;
}

module.exports = {
  insertEscrow,
  findEscrowBySwapId,
  findEscrowByOrderId: async (orderId) => {
    const r = await query(`SELECT ${ESCROW_SELECT} FROM escrows WHERE order_id = $1`, [orderId]);
    return r.rows[0] || null;
  },
  findEscrowsBySwapIds,
  releaseEscrowBySwapId,
  refundEscrowBySwapId,
  releaseEscrowByOrderId: async (orderId, client) => {
    const r = await run(
      client,
      `UPDATE escrows SET status = 'RELEASED' WHERE order_id = $1 AND status = 'HELD' RETURNING ${ESCROW_SELECT}`,
      [orderId]
    );
    return r.rows[0] || null;
  },
  refundEscrowByOrderId: async (orderId, client) => {
    const r = await run(
      client,
      `UPDATE escrows SET status = 'REFUNDED' WHERE order_id = $1 AND status = 'HELD' RETURNING ${ESCROW_SELECT}`,
      [orderId]
    );
    return r.rows[0] || null;
  },
  findEscrowsByOrderIds,
};
