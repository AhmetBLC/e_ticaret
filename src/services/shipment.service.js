const crypto = require("crypto");
const AppError = require("../utils/AppError");
const shipmentModel = require("../models/shipment.model");
const workOrderModel = require("../models/workOrder.model");
const swapModel = require("../models/swap.model");
const orderModel = require("../models/order.model");
const { SHIPMENT_STATUS, SHIPMENT_TRANSITIONS } = require("../constants/shipmentStatus");
const { generateTrackingNumber } = require("../utils/trackingNumber");
const logger = require("../utils/logger");

/**
 * Generate a simulated barcode string for cargo label.
 * In production this would generate a PDF label / scan-ready barcode.
 */
function generateBarcode(trackingNumber) {
  const hash = crypto.createHash("md5").update(trackingNumber).digest("hex").substring(0, 16).toUpperCase();
  return `BC-${hash}`;
}

/**
 * Calculate simulated estimated delivery date (3-5 business days).
 */
function calculateEstimatedDelivery() {
  const days = 3 + Math.floor(Math.random() * 3); // 3-5 days
  const date = new Date();
  date.setDate(date.getDate() + days);
  return date.toISOString().slice(0, 10);
}

/**
 * Create a new shipment with tracking number and barcode.
 */
async function createShipment({
  orderId,
  swapId,
  senderUserId,
  receiverUserId,
  senderAddressId,
  receiverAddressId,
  carrier = "SimKargo",
  weightKg,
}, client) {
  const trackingNumber = generateTrackingNumber();
  const barcode = generateBarcode(trackingNumber);
  const estimatedDelivery = calculateEstimatedDelivery();

  const shipment = await shipmentModel.insertShipment(
    {
      orderId,
      swapId,
      senderUserId,
      receiverUserId,
      senderAddressId,
      receiverAddressId,
      trackingNumber,
      barcode,
      carrier,
      status: SHIPMENT_STATUS.LABEL_CREATED,
      estimatedDelivery,
      weightKg,
    },
    client
  );

  logger.info("shipment_created", {
    shipmentId: shipment.id,
    trackingNumber,
    barcode,
    carrier,
    estimatedDelivery,
  });

  return shipment;
}

/**
 * Advance shipment to next status (validates allowed transitions).
 */
async function advanceShipmentStatus(shipmentId, newStatus, client) {
  const shipment = await shipmentModel.findShipmentById(shipmentId);
  if (!shipment) {
    throw new AppError("Shipment not found", 404, "NOT_FOUND");
  }

  if (shipment.status === newStatus) {
    return shipment; // No action needed
  }

  const allowedNext = SHIPMENT_TRANSITIONS[shipment.status];
  if (!allowedNext || !allowedNext.includes(newStatus)) {
    throw new AppError(
      `Cannot transition from ${shipment.status} to ${newStatus}`,
      400,
      "INVALID_STATUS_TRANSITION"
    );
  }

  const updated = await shipmentModel.updateShipmentStatus(shipmentId, newStatus, client);
  logger.info("shipment_status_updated", {
    shipmentId,
    from: shipment.status,
    to: newStatus,
    trackingNumber: shipment.tracking_number,
  });

  return updated;
}

/**
 * Track a shipment by tracking number (public).
 */
async function trackShipment(trackingNumber) {
  const shipment = await shipmentModel.findShipmentByTracking(trackingNumber);
  if (!shipment) {
    throw new AppError("Shipment not found — invalid tracking number", 404, "NOT_FOUND");
  }
  return { shipment };
}

/**
 * Get shipment details by ID.
 */
async function getShipmentById(shipmentId) {
  const shipment = await shipmentModel.findShipmentById(shipmentId);
  if (!shipment) {
    throw new AppError("Shipment not found", 404, "NOT_FOUND");
  }
  return { shipment };
}

/**
 * List shipments for an order.
 */
async function getShipmentsByOrder(orderId) {
  const shipments = await shipmentModel.findShipmentsByOrderId(orderId);
  return { shipments };
}

/**
 * List all shipments involving a user (as sender or receiver).
 */
async function getMyShipments(userId, page = 1, limit = 20) {
  const offset = (page - 1) * limit;
  const shipments = await shipmentModel.findShipmentsByUser(userId, { limit, offset });
  return { shipments };
}

async function listAllShipments(page = 1, limit = 50) {
  const offset = (page - 1) * limit;
  const shipments = await shipmentModel.findAllShipments({ limit, offset });
  return { shipments };
}

/**
 * Simulate the entire cargo progression in one call (for demo purposes).
 * Advances through: LABEL_CREATED → PICKED_UP → IN_TRANSIT → OUT_FOR_DELIVERY → DELIVERED
 */
async function simulateDelivery(shipmentId) {
  const fullProgression = [
    SHIPMENT_STATUS.PICKED_UP,
    SHIPMENT_STATUS.IN_TRANSIT,
    SHIPMENT_STATUS.OUT_FOR_DELIVERY,
    SHIPMENT_STATUS.DELIVERED,
  ];

  // Get current status and start from there
  const current = await shipmentModel.findShipmentById(shipmentId);
  if (!current) {
    throw new AppError("Shipment not found", 404, "NOT_FOUND");
  }

  // Find where we are in the progression
  const currentIdx = fullProgression.indexOf(current.status);
  // If already delivered or not in progression, start from the beginning
  const startIdx = currentIdx >= 0 ? currentIdx + 1 : 0;
  const remaining = fullProgression.slice(startIdx);

  let result = current;
  for (const status of remaining) {
    try {
      result = await advanceShipmentStatus(shipmentId, status);
    } catch {
      // If transition fails, skip
      continue;
    }
  }
  return result;
}

/**
 * Initiates shipments for a given Work Order (Swap or Order).
 * If swap: creates 2 shipments (Requester to Workshop, Receiver to Workshop).
 * If order: creates 1 shipment (Seller to Buyer).
 */
async function initiateShipmentForWorkOrder(workOrderId) {
  const wo = await workOrderModel.findWorkOrderById(workOrderId);
  if (!wo) {
    throw new AppError("Work Order not found", 404, "NOT_FOUND");
  }

  // Check if shipments already exist
  const existing = wo.swap_id 
    ? await shipmentModel.findShipmentsBySwapId(wo.swap_id)
    : await shipmentModel.findShipmentsByOrderId(wo.order_id);
    
  if (existing && existing.length > 0) {
    throw new AppError("Shipments already initiated for this work order", 409, "ALREADY_EXISTS");
  }

  const results = [];

  if (wo.swap_id) {
    const swap = await swapModel.findSwapById(wo.swap_id);
    // 1. From Requester to Receiver
    const s1 = await createShipment({
      swapId: wo.swap_id,
      senderUserId: swap.requester_user_id,
      receiverUserId: swap.receiver_user_id,
    });
    // 2. From Receiver to Requester
    const s2 = await createShipment({
      swapId: wo.swap_id,
      senderUserId: swap.receiver_user_id,
      receiverUserId: swap.requester_user_id,
    });
    results.push(s1, s2);
  } else if (wo.order_id) {
    const order = await orderModel.findOrderById(wo.order_id);
    const orderItems = await orderModel.findOrderItemsByOrderIds([wo.order_id]);
    
    // Find seller from the first product in the order
    const firstItem = orderItems[0];
    const productModel = require("../models/product.model");
    const product = await productModel.findProductById(firstItem.product_id);
    const sellerId = product.user_id;

    const s = await createShipment({
      orderId: wo.order_id,
      senderUserId: sellerId,
      receiverUserId: order.user_id,
    });
    results.push(s);
  }

  return results;
}

module.exports = {
  createShipment,
  getShipmentById,
  trackShipment,
  getMyShipments,
  getShipmentsByOrder,
  advanceShipmentStatus,
  simulateDelivery,
  listAllShipments,
  initiateShipmentForWorkOrder,
};
