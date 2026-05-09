const PAYMENT_STATUS = Object.freeze({
  PENDING: "PENDING",
  AWAITING_3DS: "AWAITING_3DS",
  PAID: "PAID",
  /** Money held in pool (for escrow / swap price diff) */
  HELD: "HELD",
  /** Released from pool to recipient */
  RELEASED: "RELEASED",
  REFUNDED: "REFUNDED",
  FAILED: "FAILED",
});

const PAYMENT_METHOD = Object.freeze({
  CARD: "CARD",
  WALLET: "WALLET",
});

module.exports = { PAYMENT_STATUS, PAYMENT_METHOD };
