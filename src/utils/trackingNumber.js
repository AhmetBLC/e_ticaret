const crypto = require("crypto");

/**
 * Simulated cargo tracking id, e.g. ETC-20260328-A1B2C3D4 (unique per generation).
 */
/**
 * Simulated cargo tracking id: Yurtici Kargo style (12 digits).
 */
function generateTrackingNumber() {
  return Math.floor(Math.random() * 900000000000 + 100000000000).toString();
}

/**
 * Public tracking code for guest checkouts: TRK-XXXX-XXXX.
 */
function generateGuestTrackingCode() {
  const rand = crypto.randomBytes(4).toString("hex").toUpperCase();
  return `TRK-${rand.slice(0, 4)}-${rand.slice(4)}`;
}

module.exports = { 
  generateTrackingNumber,
  generateGuestTrackingCode
};
