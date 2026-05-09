const AppError = require("../utils/AppError");
const productModel = require("../models/product.model");
const userModel = require("../models/user.model");
const swapModel = require("../models/swap.model");
const workOrderModel = require("../models/workOrder.model");
const { query } = require("../config/database");

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 100;

function normalizePagination(page, limit) {
  const p = Number.isFinite(page) && page > 0 ? Math.floor(page) : 1;
  let l = Number.isFinite(limit) && limit > 0 ? Math.floor(limit) : DEFAULT_LIMIT;
  if (l > MAX_LIMIT) {
    l = MAX_LIMIT;
  }
  const offset = (p - 1) * l;
  return { page: p, limit: l, offset };
}

async function getDashboardStats() {
  const [productsR, usersR, swapsR, ordersR, pendingWoR] = await Promise.all([
    query("SELECT COUNT(*)::bigint AS c FROM products"),
    query("SELECT COUNT(*)::bigint AS c FROM users"),
    query("SELECT COUNT(*)::bigint AS c FROM swaps"),
    query("SELECT COUNT(*)::bigint AS c FROM orders"),
    query("SELECT COUNT(*)::bigint AS c FROM work_orders WHERE status = 'PENDING'"),
  ]);

  return {
    stats: {
      total_products: Number(productsR.rows[0].c),
      total_users: Number(usersR.rows[0].c),
      total_swaps: Number(swapsR.rows[0].c),
      total_orders: Number(ordersR.rows[0].c),
      pending_work_orders: Number(pendingWoR.rows[0].c),
    },
  };
}

async function listAllUsers(queryParams) {
  const page = queryParams.page != null ? Number(queryParams.page) : 1;
  const limit = queryParams.limit != null ? Number(queryParams.limit) : DEFAULT_LIMIT;
  const { page: p, limit: l, offset } = normalizePagination(page, limit);

  const [totalR, rowsR] = await Promise.all([
    query("SELECT COUNT(*)::bigint AS c FROM users"),
    query(
      `SELECT id, email, role, created_at
       FROM users
       ORDER BY created_at DESC
       LIMIT $1 OFFSET $2`,
      [l, offset]
    ),
  ]);

  const total = Number(totalR.rows[0].c);
  const totalPages = l > 0 ? Math.ceil(total / l) : 0;

  return {
    users: rowsR.rows,
    pagination: { page: p, limit: l, total, total_pages: totalPages },
  };
}

async function listAllSwaps(queryParams) {
  const page = queryParams.page != null ? Number(queryParams.page) : 1;
  const limit = queryParams.limit != null ? Number(queryParams.limit) : DEFAULT_LIMIT;
  const status = typeof queryParams.status === "string" && queryParams.status.trim()
    ? queryParams.status.trim()
    : null;
  const { page: p, limit: l, offset } = normalizePagination(page, limit);

  const params = [];
  let where = "1=1";
  if (status) {
    params.push(status);
    where = `status = $1`;
  }

  const limitIdx = params.length + 1;
  const offsetIdx = params.length + 2;
  params.push(l, offset);

  const [totalR, rowsR] = await Promise.all([
    query(`SELECT COUNT(*)::bigint AS c FROM swaps WHERE ${where}`, status ? [status] : []),
    query(
      `SELECT id, requester_user_id, receiver_user_id, product_offered_id, product_requested_id, status, created_at
       FROM swaps
       WHERE ${where}
       ORDER BY created_at DESC
       LIMIT $${limitIdx} OFFSET $${offsetIdx}`,
      params
    ),
  ]);

  const total = Number(totalR.rows[0].c);
  const totalPages = l > 0 ? Math.ceil(total / l) : 0;

  return {
    swaps: rowsR.rows,
    pagination: { page: p, limit: l, total, total_pages: totalPages },
  };
}

async function listAllProducts(queryParams) {
  const page = queryParams.page != null ? Number(queryParams.page) : 1;
  const limit = queryParams.limit != null ? Number(queryParams.limit) : DEFAULT_LIMIT;
  const { page: p, limit: l, offset } = normalizePagination(page, limit);

  // Admin sees ALL products including sold/unavailable ones
  const [total, rows] = await Promise.all([
    productModel.countProducts({ onlyAvailable: false }),
    productModel.findProductsPaginated({ limit: l, offset, onlyAvailable: false }),
  ]);

  const totalPages = l > 0 ? Math.ceil(total / l) : 0;

  return {
    products: rows,
    pagination: { page: p, limit: l, total, total_pages: totalPages },
  };
}

async function listAllOrders(queryParams) {
  const page = queryParams.page != null ? Number(queryParams.page) : 1;
  const limit = queryParams.limit != null ? Number(queryParams.limit) : DEFAULT_LIMIT;
  const { page: p, limit: l, offset } = normalizePagination(page, limit);

  const [totalR, rowsR] = await Promise.all([
    query("SELECT COUNT(*)::bigint AS c FROM orders"),
    query(
      `SELECT id, user_id, status, tracking_number, created_at
       FROM orders
       ORDER BY created_at DESC
       LIMIT $1 OFFSET $2`,
      [l, offset]
    ),
  ]);

  const total = Number(totalR.rows[0].c);
  const totalPages = l > 0 ? Math.ceil(total / l) : 0;

  return {
    orders: rowsR.rows,
    pagination: { page: p, limit: l, total, total_pages: totalPages },
  };
}

module.exports = {
  getDashboardStats,
  listAllUsers,
  listAllSwaps,
  listAllProducts,
  listAllOrders,
};
