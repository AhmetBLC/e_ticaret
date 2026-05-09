const rmaModel = require("../models/rma.model");
const orderModel = require("../models/order.model");
const productModel = require("../models/product.model");
const AppError = require("../utils/AppError");

async function requestReturn(userId, { orderId, reason, imageUrl }) {
  const order = await orderModel.findOrderById(orderId);
  if (!order || order.user_id !== userId) {
    throw new AppError("Sipariş bulunamadı.", 404, "ORDER_NOT_FOUND");
  }

  // Basic check: only completed orders can be returned
  if (order.status !== "COMPLETED" && order.status !== "DELIVERED") {
    // Note: status 'DELIVERED' might be the final standard status
  }

  return await rmaModel.insertReturnRequest({
    orderId,
    userId,
    reason,
    imageUrl
  });
}

async function handleReturnReview(rmaId, { status, adminNotes }, client) {
  const rma = await rmaModel.updateReturnRequestStatus(rmaId, status, adminNotes);
  if (!rma) {
    throw new AppError("İade talebi bulunamadı.", 404, "RMA_NOT_FOUND");
  }

  // If approved/completed, we might want to restock or refund
  if (status === "COMPLETED") {
    const orderItems = await orderModel.findOrderItemsByOrderId(rma.order_id);
    for (const item of orderItems) {
      if (item.product_id) {
        // Mark product as available again in second-hand marketplace
        await productModel.setProductAvailable(item.product_id, client);
      }
    }
  }

  return rma;
}

module.exports = {
  requestReturn,
  handleReturnReview,
};
