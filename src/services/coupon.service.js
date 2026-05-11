const couponModel = require("../models/coupon.model");
const AppError = require("../utils/AppError");

async function validateCoupon(code, cartTotal) {
  const coupon = await couponModel.findCouponByCode(code);
  
  if (!coupon) {
    throw new AppError("Geçersiz veya süresi dolmuş kupon.", 400, "INVALID_COUPON");
  }

  if (cartTotal < Number(coupon.min_purchase_amount)) {
    throw new AppError(
      "COUPON_MIN_PURCHASE", 
      `Bu kupon için minimum harfama tutarı ${coupon.min_purchase_amount} ₺ olmalıdır.`, 
      400
    );
  }

  let discountAmount = 0;
  if (coupon.discount_type === "PERCENTAGE") {
    discountAmount = cartTotal * (Number(coupon.value) / 100);
  } else {
    discountAmount = Number(coupon.value);
  }

  // Cap discount to cart total
  discountAmount = Math.min(discountAmount, cartTotal);

  return {
    couponId: coupon.id,
    code: coupon.code,
    discountAmount
  };
}

module.exports = {
  validateCoupon,
};
