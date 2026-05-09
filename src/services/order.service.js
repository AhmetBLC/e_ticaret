const AppError = require("../utils/AppError");
const { withTransaction } = require("../config/database");
const { ORDER_STATUS } = require("../constants/orderStatus");
const orderModel = require("../models/order.model");
const variantModel = require("../models/variant.model");
const { generateTrackingNumber } = require("../utils/trackingNumber");

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

/**
 * Merge duplicate variant lines and sum quantities.
 */
function mergeLineItems(items) {
  const map = new Map();
  for (const raw of items) {
    const variantId = raw.variant_id;
    const qty = Math.trunc(Number(raw.quantity));
    if (!variantId) {
      continue;
    }
    const prev = map.get(variantId) || 0;
    map.set(variantId, prev + qty);
  }
  return [...map.entries()].map(([variant_id, quantity]) => ({
    variant_id,
    quantity,
  }));
}

function serializeOrderItem(row) {
  return {
    id: row.id,
    order_id: row.order_id,
    product_id: row.product_id,
    variant_id: row.variant_id,
    quantity: Number(row.quantity),
    price: row.price != null ? Number(row.price) : null,
  };
}

function serializeOrder(row, items) {
  return {
    id: row.id,
    user_id: row.user_id,
    status: row.status,
    created_at: row.created_at,
    tracking_number: row.tracking_number ?? null,
    guest_tracking_code: row.guest_tracking_code ?? null,
    total_amount: row.total_amount ? Number(row.total_amount) : null,
    items: items.map(serializeOrderItem),
  };
}

function groupItemsByOrderId(itemRows) {
  const map = new Map();
  for (const row of itemRows) {
    if (!map.has(row.order_id)) {
      map.set(row.order_id, []);
    }
    map.get(row.order_id).push(row);
  }
  return map;
}

async function createOrder(userId, body) {
  const merged = mergeLineItems(body.items || []);
  if (merged.length === 0) {
    throw new AppError(
      "At least one order line with variant_id and quantity is required",
      400,
      "VALIDATION_ERROR"
    );
  }

  for (const line of merged) {
    if (!Number.isInteger(line.quantity) || line.quantity < 1) {
      throw new AppError(
        "Each item must have a positive integer quantity",
        400,
        "VALIDATION_ERROR"
      );
    }
  }

  const sortedLines = [...merged].sort((a, b) =>
    a.variant_id.localeCompare(b.variant_id)
  );

  const orderRow = await withTransaction(async (client) => {
    const locked = [];
    for (const line of sortedLines) {
      const v = await variantModel.findVariantByIdForUpdate(
        line.variant_id,
        client
      );
      if (!v) {
        throw new AppError(
          `Variant not found: ${line.variant_id}`,
          404,
          "NOT_FOUND"
        );
      }
      if (v.stock < line.quantity) {
        throw new AppError(
          `Insufficient stock for variant ${line.variant_id}`,
          409,
          "INSUFFICIENT_STOCK"
        );
      }
      locked.push({ variant: v, quantity: line.quantity });
    }

    const order = await orderModel.insertOrder(
      { 
        userId, 
        status: ORDER_STATUS.PENDING, 
        totalAmount: body.totalAmount,
        guestTrackingCode: body.guestTrackingCode 
      },
      client
    );

    for (const { variant: v, quantity } of locked) {
      await orderModel.insertOrderItem(
        {
          orderId: order.id,
          productId: v.product_id,
          variantId: v.id,
          quantity,
          price: v.price,
        },
        client
      );
      const ok = await variantModel.decrementVariantStock(
        v.id,
        quantity,
        client
      );
      if (!ok) {
        throw new AppError(
          "Could not update stock (try again)",
          409,
          "INSUFFICIENT_STOCK"
        );
      }
    }

    return order;
  });

  const items = await orderModel.findOrderItemsByOrderIds([orderRow.id]);
  return { order: serializeOrder(orderRow, items) };
}

async function getOrderByGuestCode(code) {
  const row = await orderModel.findOrderByGuestCode(code);
  if (!row) {
    throw new AppError("ORDER_NOT_FOUND", "Sipariş bulunamadı.", 404);
  }
  const items = await orderModel.findOrderItemsByOrderIds([row.id]);
  return serializeOrder(row, items);
}

function generateInvoiceText(order) {
  const lines = [
    "------------------------------------------",
    "        E-TICARET ATOLYE FATURA          ",
    "------------------------------------------",
    `Siparis ID: ${order.id}`,
    `Tarih: ${new Date(order.created_at).toLocaleString()}`,
    `Durum: ${order.status}`,
    "------------------------------------------",
    "Urun                    Adet    Fiyat     ",
  ];

  order.items.forEach(item => {
    lines.push(`${item.id.slice(0, 10)}...      ${item.quantity}       ${item.price} TL`);
  });

  lines.push("------------------------------------------");
  if (order.total_amount) {
    lines.push(`TOPLAM: ${order.total_amount} TL`);
  }
  lines.push("------------------------------------------");
  lines.push("Yurtici Kargo ile gonderilecektir.");
  lines.push("------------------------------------------");
  
  return lines.join("\n");
}

async function listOrders(userId, query) {
  const page = query.page != null ? Number(query.page) : 1;
  const limit = query.limit != null ? Number(query.limit) : DEFAULT_LIMIT;
  const { page: p, limit: l, offset } = normalizePagination(page, limit);

  const [total, orderRows] = await Promise.all([
    orderModel.countOrdersByUser(userId),
    orderModel.findOrdersByUserPaginated({ userId, limit: l, offset }),
  ]);

  const orderIds = orderRows.map((o) => o.id);
  const itemRows = await orderModel.findOrderItemsByOrderIds(orderIds);
  const byOrder = groupItemsByOrderId(itemRows);

  const totalPages = l > 0 ? Math.ceil(total / l) : 0;

  return {
    orders: orderRows.map((o) =>
      serializeOrder(o, byOrder.get(o.id) || [])
    ),
    pagination: {
      page: p,
      limit: l,
      total,
      total_pages: totalPages,
    },
  };
}

/**
 * Simulates cargo: PENDING → SHIPPED assigns a unique tracking_number;
 * SHIPPED → DELIVERED completes the order (tracking unchanged).
 */
async function advanceOrderStatus(userId, orderId, nextStatus) {
  const order = await orderModel.findOrderByIdAndUser(orderId, userId);
  if (!order) {
    throw new AppError("Order not found", 404, "NOT_FOUND");
  }

  if (order.status === ORDER_STATUS.DELIVERED) {
    throw new AppError("Order is already completed", 409, "INVALID_STATUS");
  }

  if (nextStatus === ORDER_STATUS.SHIPPED) {
    if (order.status !== ORDER_STATUS.PENDING) {
      throw new AppError(
        "Only pending orders can be marked as shipped",
        409,
        "INVALID_STATUS"
      );
    }
    let lastPgError;
    for (let attempt = 0; attempt < 12; attempt++) {
      const tracking = generateTrackingNumber();
      try {
        const row = await orderModel.updateOrderFields(orderId, {
          status: ORDER_STATUS.SHIPPED,
          trackingNumber: tracking,
        });
        if (!row) {
          throw new AppError("Order not found", 404, "NOT_FOUND");
        }
        const items = await orderModel.findOrderItemsByOrderIds([orderId]);
        return { order: serializeOrder(row, items) };
      } catch (err) {
        if (err.code === "23505") {
          lastPgError = err;
          continue;
        }
        throw err;
      }
    }
    throw new AppError(
      lastPgError ? "Tracking number collision" : "Could not ship order",
      500,
      "TRACKING_ERROR"
    );
  }

  if (nextStatus === ORDER_STATUS.DELIVERED) {
    if (order.status !== ORDER_STATUS.SHIPPED) {
      throw new AppError(
        "Order must be shipped before it can be delivered",
        409,
        "INVALID_STATUS"
      );
    }
    const row = await orderModel.updateOrderFields(orderId, {
      status: ORDER_STATUS.DELIVERED,
    });
    if (!row) {
      throw new AppError("Order not found", 404, "NOT_FOUND");
    }
    const items = await orderModel.findOrderItemsByOrderIds([orderId]);
    return { order: serializeOrder(row, items) };
  }

  throw new AppError("Invalid target status", 400, "VALIDATION_ERROR");
}

async function getStats(userId, role) {
  const { query: dbQuery } = require("../config/database");

  // User stats: Earnings from items sold by this user
  // (Assuming item ownership is tracked via product.user_id)
  const userStatsR = await dbQuery(
    `SELECT 
      SUM(oi.price * oi.quantity)::float as earnings,
      COUNT(DISTINCT o.id)::int as sales_count
     FROM orders o
     JOIN order_items oi ON o.id = oi.order_id
     JOIN products p ON oi.product_id = p.id
     WHERE p.user_id = $1 AND o.status = 'DELIVERED'`,
    [userId]
  );

  const stats = {
    user_earnings: userStatsR.rows[0].earnings || 0,
    user_sales_count: userStatsR.rows[0].sales_count || 0,
  };

  // Admin stats: Platform-wide summary
  if (role === "ADMIN") {
    const adminStatsR = await dbQuery(
      `SELECT 
        SUM(total_amount)::float as total_sales,
        COUNT(*)::int as order_count
       FROM orders
       WHERE status = 'DELIVERED'`
    );
    stats.admin_total_sales = adminStatsR.rows[0].total_sales || 0;
    stats.admin_order_count = adminStatsR.rows[0].order_count || 0;
  }

  return { stats };
}

module.exports = {
  createOrder,
  listOrders,
  advanceOrderStatus,
  getOrderByGuestCode,
  generateInvoiceText,
  getStats,
  serializeOrder,
  serializeOrderItem,
};
