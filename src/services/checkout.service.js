const AppError = require("../utils/AppError");
const { withTransaction } = require("../config/database");
const paymentService = require("./payment.service");
const shipmentService = require("./shipment.service");
const orderService = require("./order.service");
const variantModel = require("../models/variant.model");
const orderModel = require("../models/order.model");
const addressModel = require("../models/address.model");
const escrowModel = require("../models/escrow.model");
const workOrderModel = require("../models/workOrder.model");
const couponService = require("./coupon.service");
const { generateGuestTrackingCode } = require("../utils/trackingNumber");
const logger = require("../utils/logger");

/**
 * One-Page Checkout:
 * Combines address selection + payment + order creation in a single transaction.
 *
 * Flow:
 * 1. Validate items (stock check)
 * 2. Calculate total
 * 3. Initiate payment (3DS simulation)
 * 4. Create order
 * 5. Decrement stock
 * 6. Create shipment
 * 7. Return all info
 */
async function checkout(userId, {
  items,
  shipping_address_id,
  card_last_four,
  card_brand,
  skip_3ds = false,
  coupon_code = null,
}) {
  if (!items || items.length === 0) {
    throw new AppError("Cart is empty", 400, "VALIDATION_ERROR");
  }

  if (!card_last_four || !card_brand) {
    throw new AppError("Credit card details (card_last_four, card_brand) are required to complete the checkout.", 400, "VALIDATION_ERROR");
  }

  // Validate address
  let shippingAddress = null;
  if (shipping_address_id) {
    shippingAddress = await addressModel.findAddressById(shipping_address_id);
    if (!shippingAddress || shippingAddress.user_id !== userId) {
      throw new AppError("Shipping address not found", 404, "NOT_FOUND");
    }
  }

  return withTransaction(async (client) => {
    // 1. Validate and calculate
    let totalAmount = 0;
    const resolvedItems = [];

    for (const item of items) {
      const variant = await variantModel.findVariantByIdForUpdate(
        item.variant_id,
        client
      );
      if (!variant) {
        throw new AppError(
          `Variant ${item.variant_id} not found`,
          404,
          "NOT_FOUND"
        );
      }
      if (variant.stock_quantity < item.quantity) {
        throw new AppError(
          `Insufficient stock for ${variant.name}`,
          409,
          "STOCK_INSUFFICIENT"
        );
      }

      // Fetch product for fallback price if override is null
      const product = await client.query("SELECT price FROM products WHERE id = $1", [variant.product_id]);
      const effectivePrice = variant.price_override || product.rows[0].price;

      const lineTotal = Number(effectivePrice) * item.quantity;
      totalAmount += lineTotal;

      resolvedItems.push({
        variantId: variant.id,
        productId: variant.product_id,
        quantity: item.quantity,
        price: effectivePrice,
      });
    }

    // 1.5. Apply coupon if provided
    let discountAmount = 0;
    if (coupon_code) {
      const couponResult = await couponService.validateCoupon(coupon_code, totalAmount);
      discountAmount = couponResult.discountAmount;
    }
    const finalAmount = totalAmount - discountAmount;

    // 2. Create order
    const guestTrackingCode = userId ? null : generateGuestTrackingCode();
    const order = await orderModel.insertOrder(
      {
        userId,
        status: "PENDING",
        shippingAddressId: shipping_address_id,
        totalAmount: finalAmount,
        guestTrackingCode,
      },
      client
    );

    // 3. Create order items, decrement stock & mark products as sold
    const soldProductIds = new Set();
    for (const ri of resolvedItems) {
      await orderModel.insertOrderItem(
        {
          orderId: order.id,
          productId: ri.productId,
          variantId: ri.variantId,
          quantity: ri.quantity,
          price: ri.price,
        },
        client
      );
      await variantModel.decrementVariantStock(ri.variantId, ri.quantity, client);
      soldProductIds.add(ri.productId);
    }

    // 4. Initiate payment
    let payment = await paymentService.initiatePayment(
      {
        userId,
        orderId: order.id,
        amount: finalAmount,
        cardLastFour: card_last_four,
        cardBrand: card_brand,
        require3DS: !skip_3ds,
      },
      client
    );

    // If skip_3ds is true (it usually is for simulated flows here), hold the payment immediately
    // and put it in escrow
    console.log(`Payment Status for Order ${order.id}: ${payment.status} (require3DS was ${!skip_3ds})`);
    
    // Always create escrow and work order records to ensure visibility in Atölye
    // but only 'hold' the payment in the payment record if it's already PAID.
    if (payment.status === "PAID") {
      console.log(`Immediately holding payment record for Order ${order.id}`);
      payment = await paymentService.holdPayment(payment.id, client);
    }

    console.log(`Creating escrow and work order records for Order ${order.id}`);
    const escrow = await escrowModel.insertEscrow({
      orderId: order.id,
      amount: finalAmount,
      status: "HELD"
    }, client);

    const workOrder = await workOrderModel.insertWorkOrder({
      orderId: order.id,
      status: "PENDING"
    }, client);

    // 5. Create shipment (find seller from first item's product)
    let shipment = null;
    if (shippingAddress) {
      // For simplicity, we create one shipment per order from the first product's seller
      const { query: clientQuery } = client;
      const sellerR = await client.query(
        "SELECT user_id FROM products WHERE id = $1",
        [resolvedItems[0].productId]
      );
      const sellerUserId = sellerR.rows[0]?.user_id;
      if (sellerUserId) {
        shipment = await shipmentService.createShipment(
          {
            orderId: order.id,
            senderUserId: sellerUserId,
            receiverUserId: userId,
            receiverAddressId: shipping_address_id,
          },
          client
        );
      }
    }

    logger.info("checkout_complete", {
      orderId: order.id,
      paymentId: payment.id,
      totalAmount,
      itemCount: resolvedItems.length,
      shipmentId: shipment?.id,
    });

    return {
      order: orderService.serializeOrder(order, resolvedItems),
      payment,
      shipment,
      escrow,
      workOrder
    };
  });
}

module.exports = { checkout };
