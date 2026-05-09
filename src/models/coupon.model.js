const { query } = require("../config/database");

async function findCouponByCode(code) {
  const r = await query(
    "SELECT * FROM coupons WHERE code = $1 AND is_active = true AND (expires_at IS NULL OR expires_at > NOW())",
    [code]
  );
  return r.rows[0] || null;
}

async function useCoupon(id, client) {
  const run = client ? (t, p) => client.query(t, p) : query;
  // This could also decrement a 'usage_limit' if we had one
  await run("UPDATE coupons SET is_active = false WHERE id = $1", [id]);
}

module.exports = {
  findCouponByCode,
  useCoupon,
};
