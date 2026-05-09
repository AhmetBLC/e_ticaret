const AppError = require("../utils/AppError");
const { withTransaction } = require("../config/database");
const { SWAP_STATUS } = require("../constants/swapStatus");
const { WORK_ORDER_STATUS } = require("../constants/workOrderStatus");
const workOrderModel = require("../models/workOrder.model");
const swapModel = require("../models/swap.model");
const orderModel = require("../models/order.model");
const productModel = require("../models/product.model");
const escrowModel = require("../models/escrow.model");
const paymentModel = require("../models/payment.model");
const { PAYMENT_STATUS } = require("../constants/paymentStatus");

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 500;

function normalizePagination(page, limit) {
  const p = Number.isFinite(page) && page > 0 ? Math.floor(page) : 1;
  let l = Number.isFinite(limit) && limit > 0 ? Math.floor(limit) : DEFAULT_LIMIT;
  if (l > MAX_LIMIT) {
    l = MAX_LIMIT;
  }
  const offset = (p - 1) * l;
  return { page: p, limit: l, offset };
}

function serializeSwapRow(row) {
  if (!row) {
    return null;
  }
  return {
    id: row.id,
    requester_user_id: row.requester_user_id,
    receiver_user_id: row.receiver_user_id,
    product_offered_id: row.product_offered_id,
    product_requested_id: row.product_requested_id,
    status: row.status,
    created_at: row.created_at,
  };
}

function serializeOrderRow(row) {
  if (!row) return null;
  return {
    id: row.id,
    user_id: row.user_id,
    status: row.status,
    total_amount: row.total_amount != null ? Number(row.total_amount) : null,
    tracking_number: row.tracking_number,
    created_at: row.created_at,
  };
}

function serializeEscrowRow(row) {
  if (!row) {
    return null;
  }
  return {
    id: row.id,
    swap_id: row.swap_id,
    order_id: row.order_id,
    amount: row.amount != null ? Number(row.amount) : null,
    status: row.status,
    created_at: row.created_at,
  };
}

function serializeWorkOrder(row, swapRow, orderRow, escrowRow) {
  return {
    id: row.id,
    swap_id: row.swap_id,
    order_id: row.order_id,
    status: row.status,
    created_at: row.created_at,
    swap: serializeSwapRow(swapRow),
    order: serializeOrderRow(orderRow),
    escrow: serializeEscrowRow(escrowRow),
  };
}

async function listWorkOrders(query) {
  const page = query.page != null ? Number(query.page) : 1;
  const limit = query.limit != null ? Number(query.limit) : DEFAULT_LIMIT;
  const { page: p, limit: l, offset } = normalizePagination(page, limit);

  const [total, rows] = await Promise.all([
    workOrderModel.countWorkOrders(),
    workOrderModel.findWorkOrdersPaginated({ limit: l, offset }),
  ]);

  const swapIds = [...new Set(rows.map((w) => w.swap_id).filter(Boolean))];
  const orderIds = [...new Set(rows.map((w) => w.order_id).filter(Boolean))];

  const [swapMap, orderRows, swapEscrowMap, orderEscrowMap] = await Promise.all([
    swapModel.findSwapsByIds(swapIds),
    orderModel.findOrdersByIds(orderIds),
    escrowModel.findEscrowsBySwapIds(swapIds),
    escrowModel.findEscrowsByOrderIds(orderIds),
  ]);

  const orderMap = new Map(orderRows.map((o) => [o.id, o]));

  const totalPages = l > 0 ? Math.ceil(total / l) : 0;

  return {
    work_orders: rows.map((w) => {
      const escrow = w.swap_id 
        ? swapEscrowMap.get(w.swap_id) 
        : (w.order_id ? orderEscrowMap.get(w.order_id) : null);
        
      return serializeWorkOrder(
        w,
        w.swap_id ? swapMap.get(w.swap_id) : null,
        w.order_id ? orderMap.get(w.order_id) : null,
        escrow
      );
    }),
    pagination: {
      page: p,
      limit: l,
      total,
      total_pages: totalPages,
    },
  };
}

async function approveWorkOrder(workOrderId) {
  return withTransaction(async (client) => {
    const wo = await workOrderModel.findWorkOrderByIdForUpdate(
      workOrderId,
      client
    );
    if (!wo || wo.status !== WORK_ORDER_STATUS.PENDING) {
      throw new AppError(
        "Work order not found or not pending",
        404,
        "NOT_FOUND"
      );
    }

    let swapRow = null;
    let orderRow = null;

    if (wo.swap_id) {
      swapRow = await swapModel.findSwapByIdForUpdate(wo.swap_id, client);
      if (!swapRow || swapRow.status !== SWAP_STATUS.WORKSHOP) {
        throw new AppError("Swap is not in workshop review", 409, "INVALID_STATUS");
      }

      const ids = [swapRow.product_offered_id, swapRow.product_requested_id].sort();
      await productModel.findProductByIdForUpdate(ids[0], client);
      await productModel.findProductByIdForUpdate(ids[1], client);

      const transferredOffered = await productModel.transferProductToUser(
        swapRow.product_offered_id,
        swapRow.requester_user_id,
        swapRow.receiver_user_id,
        client
      );
      const transferredRequested = await productModel.transferProductToUser(
        swapRow.product_requested_id,
        swapRow.receiver_user_id,
        swapRow.requester_user_id,
        client
      );

      if (!transferredOffered || !transferredRequested) {
        throw new AppError(
          "Product ownership no longer matches this swap",
          409,
          "CONFLICT"
        );
      }

      // Products stay unavailable (sold) — they should NOT reappear in listings
      // after a completed swap. Both items have been traded.
    } else if (wo.order_id) {
      // Normal order logic
      const orderModel = require("../models/order.model");
      const { ORDER_STATUS } = require("../constants/orderStatus");
      orderRow = await orderModel.findOrderById(wo.order_id, client);
      if (!orderRow) {
         throw new AppError("Order not found", 404, "NOT_FOUND");
      }
    }

    // Release escrow
    let escrowReleased = null;
    if (wo.swap_id) {
      escrowReleased = await escrowModel.releaseEscrowBySwapId(wo.swap_id, client);
    } else if (wo.order_id) {
      escrowReleased = await escrowModel.releaseEscrowByOrderId(wo.order_id, client);
    }

    // Release the payment from pool → money goes to the recipient
    let payment = null;
    if (wo.swap_id) {
       payment = await paymentModel.findPaymentBySwapId(wo.swap_id, client);
    } else if (wo.order_id) {
       const payments = await paymentModel.findPaymentsByOrderId(wo.order_id);
       payment = payments[0] || null;
    }

    if (payment && payment.status === PAYMENT_STATUS.HELD) {
      await paymentModel.updatePaymentStatus(
        payment.id,
        PAYMENT_STATUS.RELEASED,
        client
      );
    }

    const woRow = await workOrderModel.updateWorkOrderStatus(
      wo.id,
      WORK_ORDER_STATUS.APPROVED,
      client
    );

    swapRow = null;
    if (wo.swap_id) {
      swapRow = await swapModel.updateSwapStatusFromWorkshop(
        wo.swap_id,
        SWAP_STATUS.COMPLETED,
        client
      );
      if (!swapRow) throw new AppError("Could not finalize swap", 409, "CONFLICT");
    } else if (wo.order_id) {
      // Mark order as DELIVERED
      const { ORDER_STATUS } = require("../constants/orderStatus");
      await orderModel.updateOrderFields(wo.order_id, { status: ORDER_STATUS.DELIVERED }, client);

      // Transfer ownership of products in the order to the buyer (orderRow.user_id)
      const items = await orderModel.findOrderItemsByOrderIds([wo.order_id]);
      for (const item of items) {
        const product = await productModel.findProductByIdForUpdate(item.product_id, client);
        if (product && orderRow) {
          await productModel.transferProductToUser(item.product_id, product.user_id, orderRow.user_id, client);
        }
      }
    }

    if (!woRow) {
      throw new AppError("Could not finalize work order", 409, "CONFLICT");
    }

    return {
      work_order: serializeWorkOrder(woRow, swapRow, orderRow, escrowReleased),
      escrow: escrowReleased ? serializeEscrowRow(escrowReleased) : null,
    };
  });
}

async function rejectWorkOrder(workOrderId) {
  return withTransaction(async (client) => {
    const wo = await workOrderModel.findWorkOrderByIdForUpdate(
      workOrderId,
      client
    );
    if (!wo || wo.status !== WORK_ORDER_STATUS.PENDING) {
      throw new AppError(
        "Work order not found or not pending",
        404,
        "NOT_FOUND"
      );
    }

    let swapRow = null;
    let orderRow = null;

    if (wo.swap_id) {
      swapRow = await swapModel.findSwapByIdForUpdate(wo.swap_id, client);
      if (!swapRow || swapRow.status !== SWAP_STATUS.WORKSHOP) {
        throw new AppError("Swap is not in workshop review", 409, "INVALID_STATUS");
      }
      await productModel.setProductAvailable(swapRow.product_offered_id, client);
      await productModel.setProductAvailable(swapRow.product_requested_id, client);
    } else if (wo.order_id) {
       // Order rejected by workshop. Products should probably become available again, 
       // but for simplicity we rely on the user to re-list or handle refunds manually.
       // We should at least refund the escrow.
       orderRow = await orderModel.findOrderById(wo.order_id, client);
       await orderModel.updateOrderFields(wo.order_id, { status: ORDER_STATUS.CANCELLED }, client);
    }

    // Refund escrow
    let escrowRefunded = null;
    if (wo.swap_id) {
       escrowRefunded = await escrowModel.refundEscrowBySwapId(wo.swap_id, client);
    } else if (wo.order_id) {
       escrowRefunded = await escrowModel.refundEscrowByOrderId(wo.order_id, client);
    }

    // Refund the payment back to the payer
    let payment = null;
    if (wo.swap_id) {
       payment = await paymentModel.findPaymentBySwapId(wo.swap_id, client);
    } else if (wo.order_id) {
       const payments = await paymentModel.findPaymentsByOrderId(wo.order_id);
       payment = payments[0] || null;
    }

    if (payment && [PAYMENT_STATUS.PAID, PAYMENT_STATUS.HELD].includes(payment.status)) {
      await paymentModel.updatePaymentStatus(
        payment.id,
        PAYMENT_STATUS.REFUNDED,
        client
      );
    }

    const woRow = await workOrderModel.updateWorkOrderStatus(
      wo.id,
      WORK_ORDER_STATUS.REJECTED,
      client
    );

    swapRow = null;
    if (wo.swap_id) {
      swapRow = await swapModel.updateSwapStatusFromWorkshop(
        wo.swap_id,
        SWAP_STATUS.CANCELLED,
        client
      );
      if (!swapRow) throw new AppError("Could not finalize swap", 409, "CONFLICT");
    }

    if (!woRow) {
      throw new AppError("Could not finalize work order", 409, "CONFLICT");
    }

    return {
      work_order: serializeWorkOrder(woRow, swapRow, orderRow, escrowRefunded),
      escrow: escrowRefunded ? serializeEscrowRow(escrowRefunded) : null,
    };
  });
}

module.exports = {
  listWorkOrders,
  approveWorkOrder,
  rejectWorkOrder,
};
