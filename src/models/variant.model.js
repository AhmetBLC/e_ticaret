const { query } = require("../config/database");

const VARIANT_SELECT = "id, product_id, name, price_override, stock_quantity";

function run(client, text, params) {
  return client ? client.query(text, params) : query(text, params);
}

async function insertVariants(productId, variants, client) {
  if (!variants.length) {
    return [];
  }
  const placeholders = [];
  const params = [];
  let i = 1;
  for (const v of variants) {
    placeholders.push(
      `($${i++}, $${i++}, $${i++}, $${i++})`
    );
    params.push(
      productId,
      v.name,
      v.price_override || null,
      v.stock_quantity || 0
    );
  }
  const sql = `
    INSERT INTO product_variants (product_id, name, price_override, stock_quantity)
    VALUES ${placeholders.join(", ")}
    RETURNING ${VARIANT_SELECT}
  `;
  const result = await run(client, sql, params);
  return result.rows;
}

async function deleteVariantsForProduct(productId, client) {
  await run(
    client,
    "DELETE FROM product_variants WHERE product_id = $1",
    [productId]
  );
}

async function findVariantsByProductId(productId) {
  const result = await query(
    `SELECT ${VARIANT_SELECT}
     FROM product_variants
     WHERE product_id = $1
     ORDER BY name ASC`,
    [productId]
  );
  return result.rows;
}

async function findVariantByIdForUpdate(variantId, client) {
  const r = await client.query(
    `SELECT ${VARIANT_SELECT}
     FROM product_variants
     WHERE id = $1
     FOR UPDATE`,
    [variantId]
  );
  return r.rows[0] || null;
}

async function decrementVariantStock(variantId, quantity, client) {
  const r = await client.query(
    `UPDATE product_variants
     SET stock_quantity = stock_quantity - $2
     WHERE id = $1 AND stock_quantity >= $2`,
    [variantId, quantity]
  );
  return r.rowCount === 1;
}

async function findVariantById(variantId) {
  const result = await query(
    `SELECT ${VARIANT_SELECT} FROM product_variants WHERE id = $1`,
    [variantId]
  );
  return result.rows[0] || null;
}

async function findVariantsByProductIds(productIds) {
  if (!productIds.length) return new Map();
  const result = await query(
    `SELECT ${VARIANT_SELECT} FROM product_variants WHERE product_id = ANY($1::uuid[])`,
    [productIds]
  );
  const map = new Map();
  for (const row of result.rows) {
    if (!map.has(row.product_id)) map.set(row.product_id, []);
    map.get(row.product_id).push(row);
  }
  return map;
}

module.exports = {
  insertVariants,
  deleteVariantsForProduct,
  findVariantsByProductId,
  findVariantByIdForUpdate,
  decrementVariantStock,
  findVariantById,
  findVariantsByProductIds,
};
