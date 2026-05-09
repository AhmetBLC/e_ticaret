const couponService = require("../services/coupon.service");

async function validate(req, res) {
  const { code, cartTotal } = req.body;
  const data = await couponService.validateCoupon(code, cartTotal);
  res.json({ success: true, data });
}

module.exports = {
  validate,
};
