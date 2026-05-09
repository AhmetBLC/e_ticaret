const { query } = require("../config/database");

const ADDR_SELECT =
  "id, user_id, label, full_name, phone, address_line1, address_line2, city, district, postal_code, country, is_default, created_at";

async function findAddressesByUser(userId) {
  const r = await query(
    `SELECT ${ADDR_SELECT} FROM addresses WHERE user_id = $1 ORDER BY is_default DESC, created_at DESC`,
    [userId]
  );
  return r.rows;
}

async function findAddressById(id) {
  const r = await query(`SELECT ${ADDR_SELECT} FROM addresses WHERE id = $1`, [id]);
  return r.rows[0] || null;
}

async function insertAddress(fields) {
  const r = await query(
    `INSERT INTO addresses (user_id, label, full_name, phone, address_line1, address_line2, city, district, postal_code, country, is_default)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
     RETURNING ${ADDR_SELECT}`,
    [
      fields.userId,
      fields.label || "Ev",
      fields.fullName,
      fields.phone || null,
      fields.addressLine1,
      fields.addressLine2 || null,
      fields.city,
      fields.district || null,
      fields.postalCode || null,
      fields.country || "Türkiye",
      fields.isDefault || false,
    ]
  );
  return r.rows[0];
}

async function updateAddress(id, fields) {
  const allowed = [
    "label", "full_name", "phone", "address_line1", "address_line2",
    "city", "district", "postal_code", "country", "is_default",
  ];
  const sets = [];
  const values = [];
  let i = 1;
  for (const key of allowed) {
    if (Object.prototype.hasOwnProperty.call(fields, key)) {
      sets.push(`${key} = $${i++}`);
      values.push(fields[key]);
    }
  }
  if (sets.length === 0) return null;
  values.push(id);
  const sql = `UPDATE addresses SET ${sets.join(", ")} WHERE id = $${i} RETURNING ${ADDR_SELECT}`;
  const r = await query(sql, values);
  return r.rows[0] || null;
}

async function deleteAddress(id) {
  const r = await query("DELETE FROM addresses WHERE id = $1 RETURNING id", [id]);
  return r.rowCount > 0;
}

/** Unset previous default, then set new default for user */
async function setDefaultAddress(userId, addressId) {
  await query("UPDATE addresses SET is_default = false WHERE user_id = $1", [userId]);
  const r = await query(
    `UPDATE addresses SET is_default = true WHERE id = $1 AND user_id = $2 RETURNING ${ADDR_SELECT}`,
    [addressId, userId]
  );
  return r.rows[0] || null;
}

module.exports = {
  findAddressesByUser,
  findAddressById,
  insertAddress,
  updateAddress,
  deleteAddress,
  setDefaultAddress,
};
