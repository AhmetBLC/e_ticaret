const crypto = require("crypto");
const AppError = require("../utils/AppError");
const paymentModel = require("../models/payment.model");
const { PAYMENT_STATUS } = require("../constants/paymentStatus");
const logger = require("../utils/logger");

/**
 * Simulated Iyzico / Stripe payment provider.
 * In production you'd call the real API here.
 */

/** Simulate a 3D Secure redirect URL */
function generate3DSecureUrl(paymentId) {
  return `https://sandbox-payment.example.com/3ds/verify/${paymentId}`;
}

/** Simulate a provider reference ID (like Stripe charge ID) */
function generateProviderRef() {
  return `sim-pay-${Date.now()}-${crypto.randomBytes(4).toString("hex").toUpperCase()}`;
}

/**
 * Initiate a card payment (simulates Iyzico/Stripe createPayment).
 * Returns the payment record. If 3DS is enabled, returns `three_ds_url`.
 */
async function initiatePayment({
  userId,
  orderId,
  swapId,
  amount,
  currency = "TRY",
  cardLastFour,
  cardBrand,
  require3DS = true,
}, client) {
  if (!cardLastFour) {
    cardLastFour = String(Math.floor(1000 + Math.random() * 9000));
  }
  if (!cardBrand) {
    const brands = ["Visa", "Mastercard", "Troy"];
    cardBrand = brands[Math.floor(Math.random() * brands.length)];
  }

  const providerRef = generateProviderRef();
  const status = require3DS ? PAYMENT_STATUS.AWAITING_3DS : PAYMENT_STATUS.PAID;

  const payment = await paymentModel.insertPayment(
    {
      userId,
      orderId,
      swapId,
      amount,
      currency,
      status,
      paymentMethod: "CARD",
      cardLastFour,
      cardBrand,
      providerRef,
      threeDsUrl: require3DS ? generate3DSecureUrl(providerRef) : null,
    },
    client
  );

  logger.info("payment_initiated", {
    paymentId: payment.id,
    amount,
    currency,
    status,
    require3DS,
    providerRef,
  });

  return payment;
}

/**
 * Complete 3D Secure verification (simulated callback from bank).
 * In real flow this would be called by the payment provider webhook.
 */
async function complete3DSVerification(paymentId) {
  const payment = await paymentModel.findPaymentById(paymentId);
  if (!payment) {
    throw new AppError("Payment not found", 404, "NOT_FOUND");
  }
  if (payment.status !== PAYMENT_STATUS.AWAITING_3DS) {
    throw new AppError(
      `Cannot verify 3DS — payment status is ${payment.status}`,
      400,
      "INVALID_STATUS"
    );
  }

  let updated = await paymentModel.updatePaymentStatus(paymentId, PAYMENT_STATUS.PAID);
  
  if (payment.order_id) {
     // If it's for an order, immediately hold it in the pool and create a work order
     updated = await paymentModel.updatePaymentStatus(paymentId, PAYMENT_STATUS.HELD);
     const escrowModel = require("../models/escrow.model");
     await escrowModel.insertEscrow({
       orderId: payment.order_id,
       amount: payment.amount,
       status: "HELD"
     });
     
     const workOrderModel = require("../models/workOrder.model");
     await workOrderModel.insertWorkOrder({
       orderId: payment.order_id,
       status: "PENDING"
     });
  }

  logger.info("payment_3ds_verified", { paymentId, providerRef: updated.provider_ref });
  return updated;
}

/**
 * Hold payment in escrow pool (for swap price differences).
 */
async function holdPayment(paymentId, client) {
  const payment = await paymentModel.findPaymentById(paymentId, client);
  if (!payment) {
    throw new AppError("Payment not found", 404, "NOT_FOUND");
  }
  if (payment.status !== PAYMENT_STATUS.PAID) {
    throw new AppError(
      `Cannot hold — payment status is ${payment.status}`,
      400,
      "INVALID_STATUS"
    );
  }

  const updated = await paymentModel.updatePaymentStatus(paymentId, PAYMENT_STATUS.HELD, client);
  logger.info("payment_held", { paymentId, amount: updated.amount });
  return updated;
}

/**
 * Release payment from escrow pool to the recipient.
 */
async function releasePayment(paymentId, client) {
  const payment = await paymentModel.findPaymentById(paymentId, client);
  if (!payment) {
    throw new AppError("Payment not found", 404, "NOT_FOUND");
  }
  if (payment.status !== PAYMENT_STATUS.HELD) {
    throw new AppError(
      `Cannot release — payment status is ${payment.status}`,
      400,
      "INVALID_STATUS"
    );
  }

  const updated = await paymentModel.updatePaymentStatus(paymentId, PAYMENT_STATUS.RELEASED, client);
  logger.info("payment_released", { paymentId, amount: updated.amount });
  return updated;
}

/**
 * Refund payment back to the payer.
 */
async function refundPayment(paymentId, client) {
  const payment = await paymentModel.findPaymentById(paymentId, client);
  if (!payment) {
    throw new AppError("Payment not found", 404, "NOT_FOUND");
  }
  if (![PAYMENT_STATUS.PAID, PAYMENT_STATUS.HELD].includes(payment.status)) {
    throw new AppError(
      `Cannot refund — payment status is ${payment.status}`,
      400,
      "INVALID_STATUS"
    );
  }

  const updated = await paymentModel.updatePaymentStatus(paymentId, PAYMENT_STATUS.REFUNDED, client);
  logger.info("payment_refunded", { paymentId, amount: updated.amount });
  return updated;
}

/**
 * Get user's payment history.
 */
async function getPaymentHistory(userId, page = 1, limit = 20) {
  const offset = (page - 1) * limit;
  const [payments, total] = await Promise.all([
    paymentModel.findPaymentsByUser(userId, { limit, offset }),
    paymentModel.countPaymentsByUser(userId),
  ]);
  const totalPages = limit > 0 ? Math.ceil(total / limit) : 0;
  return {
    payments,
    pagination: { page, limit, total, total_pages: totalPages },
  };
}

async function getPaymentById(paymentId) {
  const payment = await paymentModel.findPaymentById(paymentId);
  if (!payment) {
    throw new AppError("Payment not found", 404, "NOT_FOUND");
  }
  return { payment };
}

module.exports = {
  initiatePayment,
  complete3DSVerification,
  holdPayment,
  releasePayment,
  refundPayment,
  getPaymentHistory,
  getPaymentById,
};
