const paymentService = require("../services/payment.service");

async function initiate(req, res) {
  const payment = await paymentService.initiatePayment({
    userId: req.user.id,
    orderId: req.body.order_id,
    swapId: req.body.swap_id,
    amount: req.body.amount,
    currency: req.body.currency,
    cardLastFour: req.body.card_last_four,
    cardBrand: req.body.card_brand,
    require3DS: req.body.require_3ds !== false,
  });
  res.status(201).json({ success: true, data: { payment } });
}

async function verify3DS(req, res) {
  const payment = await paymentService.complete3DSVerification(req.params.id);
  res.json({ success: true, data: { payment } });
}

async function history(req, res) {
  const page = Number(req.query.page) || 1;
  const limit = Number(req.query.limit) || 20;
  const data = await paymentService.getPaymentHistory(req.user.id, page, limit);
  res.json({ success: true, data });
}

async function getById(req, res) {
  const data = await paymentService.getPaymentById(req.params.id);
  res.json({ success: true, data });
}

async function refund(req, res) {
  const payment = await paymentService.refundPayment(req.params.id);
  res.json({ success: true, data: { payment } });
}

module.exports = { initiate, verify3DS, history, getById, refund };
