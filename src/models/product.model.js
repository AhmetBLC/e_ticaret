const { query } = require("../config/database");
const { slugify } = require("../utils/slugify");
const variantModel = require("./variant.model");

const LIST_SELECT = `
  id, title, slug, description, price, user_id, category_id, created_at, is_available, image_url, city, district, meta_title, meta_description,
  (SELECT AVG(rating)::float FROM product_reviews WHERE product_reviews.product_id = id) as average_rating,
  (SELECT COUNT(*)::int FROM product_reviews WHERE product_reviews.product_id = id) as review_count,
  (SELECT COUNT(*)::int FROM favorites WHERE product_id = id) as favorite_count
`;

function run(client, text, params) {
  return client ? client.query(text, params) : query(text, params);
}

async function insertProduct(
  {
    userId,
    title,
    description,
    price,
    categoryId,
    imageUrl,
    city,
    district,
    metaTitle,
    metaDescription,
    slug
  },
  client
) {
  const suffix = Math.random().toString(36).substring(2, 7);
  const finalSlug = (slug || slugify(title)) + "-" + suffix;
  const result = await run(
    client,
    `INSERT INTO products (title, slug, description, price, user_id, category_id, image_url, city, district, meta_title, meta_description)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
     RETURNING ${LIST_SELECT}`,
    [title, finalSlug, description ?? null, price, userId, categoryId ?? null, imageUrl ?? null, city ?? null, district ?? null, metaTitle ?? null, metaDescription ?? null]
  );
  return result.rows[0];
}

async function findProductById(id) {
  const result = await query(
    `SELECT ${LIST_SELECT} FROM products p WHERE p.id = $1`,
    [id]
  );
  const product = result.rows[0] || null;
  if (product) {
    product.additional_images = (await getProductImages(id)).map(img => img.url);
    product.variants = await variantModel.findVariantsByProductId(id);
  }
  return product;
}

/** @param {string[]} ids */
async function findProductsByIds(ids) {
  if (!ids.length) {
    return [];
  }
  const result = await query(
    `SELECT ${LIST_SELECT} FROM products WHERE id = ANY($1::uuid[])`,
    [ids]
  );
  return result.rows;
}

async function findProductByIdForUpdate(productId, client) {
  const r = await client.query(
    `SELECT ${LIST_SELECT} FROM products WHERE id = $1 FOR UPDATE`,
    [productId]
  );
  return r.rows[0] || null;
}

/**
 * Marks a product unavailable if it is still available and owned by ownerUserId.
 */
async function setProductUnavailable(productId, ownerUserId, client) {
  const r = await client.query(
    `UPDATE products
     SET is_available = false
     WHERE id = $1 AND user_id = $2 AND is_available = true
     RETURNING ${LIST_SELECT}`,
    [productId, ownerUserId]
  );
  return r.rows[0] || null;
}

async function setProductAvailable(productId, client) {
  const run = client ? (t, p) => client.query(t, p) : query;
  const r = await run(
    `UPDATE products
     SET is_available = true
     WHERE id = $1
     RETURNING ${LIST_SELECT}`,
    [productId]
  );
  return r.rows[0] || null;
}

/**
 * Moves a product to a new owner if `fromUserId` still owns it.
 */
async function transferProductToUser(productId, fromUserId, toUserId, client) {
  const r = await client.query(
    `UPDATE products
     SET user_id = $3
     WHERE id = $1 AND user_id = $2
     RETURNING ${LIST_SELECT}`,
    [productId, fromUserId, toUserId]
  );
  return r.rows[0] || null;
}

async function countProducts({ onlyAvailable = true, query: q, categoryId, city } = {}) {
  let where = onlyAvailable ? "WHERE is_available = true" : "WHERE 1=1";
  const params = [];
  let i = 1;

  if (q) {
    where += ` AND (title ILIKE $${i} OR description ILIKE $${i})`;
    params.push(`%${q}%`);
    i++;
  }
  if (categoryId) {
    where += ` AND category_id = $${i}`;
    params.push(categoryId);
    i++;
  }
  if (city) {
    where += ` AND city = $${i}`;
    params.push(city);
    i++;
  }

  const result = await query(`SELECT COUNT(*)::bigint AS c FROM products ${where}`, params);
  return Number(result.rows[0].c);
}

async function findProductsPaginated({ limit, offset, onlyAvailable = true, query: q, categoryId, city }) {
  let where = onlyAvailable ? "WHERE is_available = true" : "WHERE 1=1";
  const params = [limit, offset];
  let i = 3;

  if (q) {
    where += ` AND (title ILIKE $${i} OR description ILIKE $${i})`;
    params.push(`%${q}%`);
    i++;
  }
  if (categoryId) {
    where += ` AND category_id = $${i}`;
    params.push(categoryId);
    i++;
  }
  if (city) {
    where += ` AND city = $${i}`;
    params.push(city);
    i++;
  }

  const result = await query(
    `SELECT ${LIST_SELECT}
     FROM products p
     ${where.replace(/title/g, 'p.title').replace(/description/g, 'p.description').replace(/category_id/g, 'p.category_id').replace(/city/g, 'p.city')}
     ORDER BY p.created_at DESC
     LIMIT $1 OFFSET $2`,
    params
  );
  return result.rows;
}

async function countProductsByUser(userId) {
  const result = await query(
    "SELECT COUNT(*)::bigint AS c FROM products WHERE user_id = $1",
    [userId]
  );
  return Number(result.rows[0].c);
}

async function findProductsByUserPaginated({ userId, limit, offset }) {
  const result = await query(
    `SELECT ${LIST_SELECT}
     FROM products
     WHERE user_id = $1
     ORDER BY created_at DESC
     LIMIT $2 OFFSET $3`,
    [userId, limit, offset]
  );
  return result.rows;
}

async function updateProduct(id, fields, client) {
  const allowed = ["title", "description", "price", "category_id", "image_url", "city", "district", "meta_title", "meta_description", "slug", "is_available"];
  
  // If title is updated but slug is not explicitly provided, regenerate slug
  if (fields.title && !fields.slug) {
    fields.slug = slugify(fields.title);
  }

  const sets = [];
  const values = [];
  let i = 1;
  for (const key of allowed) {
    if (Object.prototype.hasOwnProperty.call(fields, key)) {
      sets.push(`${key} = $${i++}`);
      values.push(fields[key]);
    }
  }
  if (sets.length === 0) {
    return null;
  }
  values.push(id);
  const sql = `
    UPDATE products
    SET ${sets.join(", ")}
    WHERE id = $${i}
    RETURNING ${LIST_SELECT}
  `;
  const result = await run(client, sql, values);
  return result.rows[0] || null;
}

async function deleteProduct(id, client) {
  const result = await run(
    client,
    "DELETE FROM products WHERE id = $1 RETURNING id",
    [id]
  );
  return result.rowCount > 0;
}

async function addProductImage(productId, url, sortOrder = 0, client) {
  const result = await run(
    client,
    `INSERT INTO product_images (product_id, url, sort_order)
     VALUES ($1, $2, $3)
     RETURNING id, url, sort_order`,
    [productId, url, sortOrder]
  );
  return result.rows[0];
}

async function getProductImages(productId) {
  const result = await query(
    "SELECT id, url, sort_order FROM product_images WHERE product_id = $1 ORDER BY sort_order ASC",
    [productId]
  );
  return result.rows;
}

async function deleteProductImage(imageId, client) {
  const result = await run(
    client,
    "DELETE FROM product_images WHERE id = $1",
    [imageId]
  );
  return result.rowCount > 0;
}

module.exports = {
  insertProduct,
  findProductById,
  findProductsByIds,
  findProductByIdForUpdate,
  setProductUnavailable,
  setProductAvailable,
  transferProductToUser,
  countProducts,
  findProductsPaginated,
  countProductsByUser,
  findProductsByUserPaginated,
  updateProduct,
  deleteProduct,
  addProductImage,
  getProductImages,
  deleteProductImage,
};
