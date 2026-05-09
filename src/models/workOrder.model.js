const { query } = require("../config/database");

const WO_SELECT = "id, swap_id, order_id, status, created_at, service_fee, inspection_cost";

function run(client, text, params) {
  return client ? client.query(text, params) : query(text, params);
}

async function insertWorkOrder({ swapId, orderId, status, serviceFee, inspectionCost }, client) {
  const r = await run(
    client,
    `INSERT INTO work_orders (swap_id, order_id, status, service_fee, inspection_cost)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING ${WO_SELECT}`,
    [swapId || null, orderId || null, status, serviceFee || 0, inspectionCost || 0]
  );
  return r.rows[0];
}

async function findWorkOrderById(id) {
  const r = await query(`SELECT ${WO_SELECT} FROM work_orders WHERE id = $1`, [
    id,
  ]);
  return r.rows[0] || null;
}

async function findWorkOrderByIdForUpdate(id, client) {
  const r = await client.query(
    `SELECT ${WO_SELECT} FROM work_orders WHERE id = $1 FOR UPDATE`,
    [id]
  );
  return r.rows[0] || null;
}

async function countWorkOrders() {
  const r = await query("SELECT COUNT(*)::bigint AS c FROM work_orders");
  return Number(r.rows[0].c);
}

async function findWorkOrdersPaginated({ limit, offset }) {
  const r = await query(
    `SELECT ${WO_SELECT}
     FROM work_orders
     ORDER BY created_at DESC
     LIMIT $1 OFFSET $2`,
    [limit, offset]
  );
  return r.rows;
}

async function updateWorkOrderStatus(id, newStatus, client) {
  const r = await run(
    client,
    `UPDATE work_orders
     SET status = $2
     WHERE id = $1 AND status = 'PENDING'
     RETURNING ${WO_SELECT}`,
    [id, newStatus]
  );
  return r.rows[0] || null;
}

async function getFinancialReport() {
  const r = await query(
    `SELECT 
       COUNT(*) as total_orders,
       SUM(service_fee)::float as total_service_fees,
       SUM(inspection_cost)::float as total_inspection_costs,
       SUM(service_fee + inspection_cost)::float as gross_revenue
     FROM work_orders
     WHERE status = 'APPROVED'`
  );
  return r.rows[0];
}

module.exports = {
  insertWorkOrder,
  findWorkOrderById,
  findWorkOrderByIdForUpdate,
  countWorkOrders,
  findWorkOrdersPaginated,
  updateWorkOrderStatus,
  getFinancialReport,
};
