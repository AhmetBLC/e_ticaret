const ESCROW_STATUS = Object.freeze({
  HELD: "HELD",
  /** Funds settled after workshop approves the swap. */
  RELEASED: "RELEASED",
  /** Held amount returned when workshop rejects (swap cancelled). */
  REFUNDED: "REFUNDED",
});

module.exports = { ESCROW_STATUS };
