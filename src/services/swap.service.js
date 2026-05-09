const AppError = require("../utils/AppError");
const { withTransaction } = require("../config/database");
const { SWAP_STATUS } = require("../constants/swapStatus");
const { WORK_ORDER_STATUS } = require("../constants/workOrderStatus");
const { ESCROW_STATUS } = require("../constants/escrowStatus");
const productModel = require("../models/product.model");
const swapModel = require("../models/swap.model");
const workOrderModel = require("../models/workOrder.model");
const escrowModel = require("../models/escrow.model");
const paymentModel = require("../models/payment.model");

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

function summarizeProduct(row) {
  if (!row) {
    return null;
  }
  return {
    id: row.id,
    title: row.title,
    price: row.price != null ? Number(row.price) : null,
  };
}

function serializeSwap(row) {
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

function serializeEscrow(row) {
  if (!row) {
    return null;
  }
  return {
    id: row.id,
    swap_id: row.swap_id,
    amount: row.amount != null ? Number(row.amount) : null,
    status: row.status,
    created_at: row.created_at,
  };
}

function computePriceDifference(offeredProduct, requestedProduct) {
  const a = Number(offeredProduct.price) || 0;
  const b = Number(requestedProduct.price) || 0;
  return Math.abs(a - b);
}

async function createSwap(requesterId, body) {
  const { product_offered_id: offeredId, product_requested_id: requestedId } =
    body;

  if (offeredId === requestedId) {
    throw new AppError(
      "Offered and requested products must be different",
      400,
      "VALIDATION_ERROR"
    );
  }

  const offered = await productModel.findProductById(offeredId);
  const requested = await productModel.findProductById(requestedId);

  if (!offered || !requested) {
    throw new AppError("One or both products were not found", 404, "NOT_FOUND");
  }

  if (offered.user_id === requested.user_id) {
    throw new AppError(
      "You cannot swap your own products",
      400,
      "VALIDATION_ERROR"
    );
  }

  if (offered.user_id !== requesterId) {
    throw new AppError(
      "You can only offer products that you own",
      403,
      "FORBIDDEN"
    );
  }

  const receiverId = requested.user_id;
  if (receiverId === requesterId) {
    throw new AppError(
      "You cannot swap your own products",
      400,
      "VALIDATION_ERROR"
    );
  }

  if (offered.is_available === false || requested.is_available === false) {
    throw new AppError(
      "One or more products are not available for swap",
      409,
      "UNAVAILABLE"
    );
  }

  const { withTransaction } = require("../config/database");

  return withTransaction(async (client) => {
    const row = await swapModel.insertSwap({
      requesterUserId: requesterId,
      receiverUserId: receiverId,
      productOfferedId: offeredId,
      productRequestedId: requestedId,
      status: SWAP_STATUS.PENDING,
    }, client);

    const offeredPrice = Number(offered.price) || 0;
    const requestedPrice = Number(requested.price) || 0;
    let paymentRow = null;
    let escrowRow = null;

    if (offeredPrice < requestedPrice) {
      // Requester owes money, must provide card
      const priceDiff = requestedPrice - offeredPrice;
      const { card_last_four, card_brand } = body;
      if (!card_last_four || !card_brand) {
        throw new AppError(
          "Card details (card_last_four, card_brand) are required because the product you want is more expensive.",
          400,
          "VALIDATION_ERROR"
        );
      }
      
      const paymentService = require("./payment.service");
      const escrowModel = require("../models/escrow.model");
      
      paymentRow = await paymentService.initiatePayment(
        {
          userId: requesterId,
          swapId: row.id,
          amount: priceDiff,
          cardLastFour: card_last_four,
          cardBrand: card_brand,
          require3DS: false,
        },
        client
      );
      paymentRow = await paymentService.holdPayment(paymentRow.id, client);
      escrowRow = await escrowModel.insertEscrow(
        {
          swapId: row.id,
          amount: priceDiff,
          status: "HELD",
        },
        client
      );
    }

    return { 
      swap: serializeSwap(row),
      payment: paymentRow || null,
      escrow: escrowRow ? serializeEscrow(escrowRow) : null
    };
  });
}

async function listSwapsForUser(userId, query) {
  const page = query.page != null ? Number(query.page) : 1;
  const limit = query.limit != null ? Number(query.limit) : DEFAULT_LIMIT;
  const { page: p, limit: l, offset } = normalizePagination(page, limit);
  const status =
    typeof query.status === "string" && query.status.trim() !== ""
      ? query.status.trim()
      : null;

  const [total, rows] = await Promise.all([
    swapModel.countSwapsForUser(userId, status),
    swapModel.findSwapsForUserPaginated({
      userId,
      status,
      limit: l,
      offset,
    }),
  ]);

  const productIds = [
    ...new Set(
      rows.flatMap((r) => [r.product_offered_id, r.product_requested_id])
    ),
  ];
  const productRows = await productModel.findProductsByIds(productIds);
  const productMap = new Map(productRows.map((pr) => [pr.id, pr]));

  const swapIds = rows.map((r) => r.id);
  const escrowMap = await escrowModel.findEscrowsBySwapIds(swapIds);

  const swaps = rows.map((row) => ({
    ...serializeSwap(row),
    offered_product: summarizeProduct(
      productMap.get(row.product_offered_id)
    ),
    requested_product: summarizeProduct(
      productMap.get(row.product_requested_id)
    ),
    escrow: escrowMap.has(row.id)
      ? serializeEscrow(escrowMap.get(row.id))
      : null,
  }));

  const totalPages = l > 0 ? Math.ceil(total / l) : 0;
  return {
    swaps,
    pagination: {
      page: p,
      limit: l,
      total,
      total_pages: totalPages,
    },
  };
}

async function acceptSwap(swapId, userId, body) {
  const data = await withTransaction(async (client) => {
    const swap = await swapModel.findSwapByIdForUpdate(swapId, client);
    if (!swap) {
      throw new AppError("Swap not found", 404, "NOT_FOUND");
    }
    if (swap.receiver_user_id !== userId) {
      throw new AppError(
        "Only the receiver can accept this swap",
        403,
        "FORBIDDEN"
      );
    }
    if (swap.status !== SWAP_STATUS.PENDING) {
      throw new AppError(
        "This swap can no longer be accepted",
        409,
        "INVALID_STATUS"
      );
    }

    const [idA, idB] = [
      swap.product_offered_id,
      swap.product_requested_id,
    ].sort();

    const first = await productModel.findProductByIdForUpdate(idA, client);
    const second = await productModel.findProductByIdForUpdate(idB, client);
    if (!first || !second) {
      throw new AppError("One or both products no longer exist", 404, "NOT_FOUND");
    }

    const offered =
      first.id === swap.product_offered_id ? first : second;
    const requested =
      first.id === swap.product_requested_id ? first : second;

    if (offered.user_id !== swap.requester_user_id) {
      throw new AppError(
        "Product ownership no longer matches this swap",
        409,
        "CONFLICT"
      );
    }
    if (requested.user_id !== swap.receiver_user_id) {
      throw new AppError(
        "Product ownership no longer matches this swap",
        409,
        "CONFLICT"
      );
    }

    if (!offered.is_available || !requested.is_available) {
      throw new AppError(
        "One or more products are no longer available for swap",
        409,
        "UNAVAILABLE"
      );
    }

    const lockedOffered = await productModel.setProductUnavailable(
      swap.product_offered_id,
      swap.requester_user_id,
      client
    );
    const lockedRequested = await productModel.setProductUnavailable(
      swap.product_requested_id,
      swap.receiver_user_id,
      client
    );

    if (!lockedOffered || !lockedRequested) {
      throw new AppError(
        "One or more products are no longer available for swap",
        409,
        "UNAVAILABLE"
      );
    }

    const row = await swapModel.updateSwapStatus(
      swapId,
      SWAP_STATUS.WORKSHOP,
      client
    );
    if (!row) {
      throw new AppError(
        "This swap can no longer be accepted",
        409,
        "INVALID_STATUS"
      );
    }

    await workOrderModel.insertWorkOrder(
      { swapId: row.id, status: WORK_ORDER_STATUS.PENDING },
      client
    );

    const priceDiff = computePriceDifference(offered, requested);
    let escrowRow = null;
    let paymentRow = null;
    const paymentService = require("./payment.service");
    
    if (priceDiff > 0) {
      const offeredPrice = Number(offered.price) || 0;
      const requestedPrice = Number(requested.price) || 0;

      if (requestedPrice < offeredPrice) {
        // Receiver owes money (requested product is cheaper)
        const { card_last_four, card_brand } = body || {};
        if (!card_last_four || !card_brand) {
          throw new AppError(
            "Card details (card_last_four, card_brand) are required because the product you are trading is cheaper.",
            400,
            "VALIDATION_ERROR"
          );
        }
        
        paymentRow = await paymentService.initiatePayment(
          {
            userId: userId,
            swapId: row.id,
            amount: priceDiff,
            cardLastFour: card_last_four,
            cardBrand: card_brand,
            require3DS: false,
          },
          client
        );
        paymentRow = await paymentService.holdPayment(paymentRow.id, client);
        escrowRow = await escrowModel.insertEscrow(
          { swapId: row.id, amount: priceDiff, status: ESCROW_STATUS.HELD },
          client
        );
      } else {
         // Requester owes money (already paid during creation)
         // We just verify escrow is already held
         escrowRow = await escrowModel.findEscrowBySwapId(row.id);
         // Find payment
         const swapPayment = await paymentModel.findPaymentBySwapId(row.id, client);
         paymentRow = swapPayment;
      }
    }

    return {
      swap: serializeSwap(row),
      escrow: escrowRow ? serializeEscrow(escrowRow) : null,
      payment: paymentRow || null,
    };
  });

  return data;
}

async function rejectSwap(swapId, userId) {
  const swap = await swapModel.findSwapById(swapId);
  if (!swap) {
    throw new AppError("Swap not found", 404, "NOT_FOUND");
  }
  if (swap.receiver_user_id !== userId) {
    throw new AppError(
      "Only the receiver can reject this swap",
      403,
      "FORBIDDEN"
    );
  }
  if (swap.status !== SWAP_STATUS.PENDING) {
    throw new AppError(
      "This swap can no longer be rejected",
      409,
      "INVALID_STATUS"
    );
  }

  const row = await swapModel.updateSwapStatus(swapId, SWAP_STATUS.REJECTED);
  if (!row) {
    throw new AppError(
      "This swap can no longer be rejected",
      409,
      "INVALID_STATUS"
    );
  }
  return { swap: serializeSwap(row) };
}

module.exports = {
  createSwap,
  listSwapsForUser,
  acceptSwap,
  rejectSwap,
};
