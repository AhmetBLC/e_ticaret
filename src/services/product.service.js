const AppError = require("../utils/AppError");
const { withTransaction } = require("../config/database");
const productModel = require("../models/product.model");
const variantModel = require("../models/variant.model");

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 100;

function normalizePagination(page, limit) {
  const p = Number.isFinite(page) && page > 0 ? Math.floor(page) : 1;
  let l = Number.isFinite(limit) && limit > 0 ? Math.floor(limit) : DEFAULT_LIMIT;
  if (l > MAX_LIMIT) {
    l = MAX_LIMIT;
  }
  const offset = (p - 1) * l;
  return { page: p, limit: l, offset };
}

function serializeVariant(row) {
  return {
    id: row.id,
    product_id: row.product_id,
    name: row.name,
    price_override: row.price_override != null ? Number(row.price_override) : null,
    stock_quantity: row.stock_quantity != null ? Number(row.stock_quantity) : 0,
  };
}

function serializeProduct(row, variantRows = []) {
  if (!row) {
    return null;
  }
  return {
    id: row.id,
    title: row.title,
    description: row.description,
    price: row.price != null ? Number(row.price) : null,
    user_id: row.user_id,
    category_id: row.category_id,
    created_at: row.created_at,
    is_available: row.is_available !== false,
    image_url: row.image_url,
    city: row.city,
    district: row.district,
    favorite_count: row.favorite_count != null ? Number(row.favorite_count) : 0,
    average_rating: row.average_rating != null ? Number(row.average_rating) : 0,
    review_count: row.review_count != null ? Number(row.review_count) : 0,
    variants: variantRows.map(serializeVariant),
  };
}

function normalizeVariantsInput(variants) {
  if (!variants || !variants.length) {
    return [];
  }
  const seen = new Set();
  const out = [];
  for (let i = 0; i < variants.length; i++) {
    const v = variants[i];
    const name = String(v.name ?? "").trim();
    const priceOverride = v.price_override != null ? Number(v.price_override) : null;
    const stockQuantity = v.stock_quantity != null ? Math.trunc(Number(v.stock_quantity)) : 0;
    
    if (!name) {
      throw new AppError(
        `variants[${i}]: name is required`,
        400,
        "VALIDATION_ERROR"
      );
    }
    if (priceOverride != null && (!Number.isFinite(priceOverride) || priceOverride < 0)) {
      throw new AppError(
        `variants[${i}]: price_override must be a number >= 0`,
        400,
        "VALIDATION_ERROR"
      );
    }
    if (!Number.isFinite(stockQuantity) || stockQuantity < 0) {
      throw new AppError(
        `variants[${i}]: stock_quantity must be a non-negative integer`,
        400,
        "VALIDATION_ERROR"
      );
    }
    if (seen.has(name)) {
      throw new AppError(
        `Duplicate variant in request: ${name}`,
        400,
        "VALIDATION_ERROR"
      );
    }
    seen.add(name);
    out.push({ name, price_override: priceOverride, stock_quantity: stockQuantity });
  }
  return out;
}

function handlePgError(err) {
  if (err.code === "23505") {
    if (err.constraint === "products_slug_key") {
      throw new AppError(
        "A product with a similar title already exists. Please try a different title.",
        409,
        "DUPLICATE_SLUG"
      );
    }
    throw new AppError(
      "A variant with this name already exists for this product",
      409,
      "DUPLICATE_VARIANT"
    );
  }
  throw err;
}

async function createProduct(userId, body) {
  const normalizedVariants = normalizeVariantsInput(body.variants);

  if (normalizedVariants.length === 0) {
    // Ensure every product has at least one base variant for checkout
    return withTransaction(async (client) => {
      const row = await productModel.insertProduct({
        userId,
        title: body.title,
        description: body.description,
        price: body.price,
        categoryId: body.category_id,
        imageUrl: body.image_url,
        city: body.city,
        district: body.district,
      }, client);

      const variantRows = await variantModel.insertVariants(
        row.id,
        [{ name: "Tek Seçenek", price_override: null, stock_quantity: 1 }],
        client
      );

      return { product: serializeProduct(row, variantRows) };
    });
  }

  try {
    const result = await withTransaction(async (client) => {
      const row = await productModel.insertProduct(
        {
          userId,
          title: body.title,
          description: body.description,
          price: body.price,
          categoryId: body.category_id,
          imageUrl: body.image_url,
          city: body.city,
          district: body.district,
        },
        client
      );
      const variantRows = await variantModel.insertVariants(
        row.id,
        normalizedVariants,
        client
      );

      // Handle additional images
      if (body.additional_images && Array.isArray(body.additional_images)) {
        for (let i = 0; i < body.additional_images.length; i++) {
          await productModel.addProductImage(row.id, body.additional_images[i], i, client);
        }
      }

      return { row, variantRows };
    });
    return {
      product: serializeProduct(result.row, result.variantRows),
    };
  } catch (err) {
    handlePgError(err);
  }
}

async function listProducts(query) {
  const page = query.page != null ? Number(query.page) : 1;
  const limit = query.limit != null ? Number(query.limit) : DEFAULT_LIMIT;
  const { page: p, limit: l, offset } = normalizePagination(page, limit);
  const [total, rows] = await Promise.all([
    productModel.countProducts(query),
    productModel.findProductsPaginated({ ...query, limit: l, offset }),
  ]);
  const totalPages = l > 0 ? Math.ceil(total / l) : 0;
  const ids = rows.map((r) => r.id);
  const variantMap = await variantModel.findVariantsByProductIds(ids);
  return {
    products: rows.map((r) =>
      serializeProduct(r, variantMap.get(r.id) || [])
    ),
    pagination: {
      page: p,
      limit: l,
      total,
      total_pages: totalPages,
    },
  };
}

async function listMyProducts(userId, query) {
  const page = query.page != null ? Number(query.page) : 1;
  const limit = query.limit != null ? Number(query.limit) : DEFAULT_LIMIT;
  const { page: p, limit: l, offset } = normalizePagination(page, limit);
  const [total, rows] = await Promise.all([
    productModel.countProductsByUser(userId),
    productModel.findProductsByUserPaginated({
      userId,
      limit: l,
      offset,
    }),
  ]);
  const totalPages = l > 0 ? Math.ceil(total / l) : 0;
  const ids = rows.map((r) => r.id);
  const variantMap = await variantModel.findVariantsByProductIds(ids);
  return {
    products: rows.map((r) =>
      serializeProduct(r, variantMap.get(r.id) || [])
    ),
    pagination: {
      page: p,
      limit: l,
      total,
      total_pages: totalPages,
    },
  };
}

async function getProductById(id) {
  const row = await productModel.findProductById(id);
  if (!row) {
    throw new AppError("Product not found", 404, "NOT_FOUND");
  }
  const variantRows = await variantModel.findVariantsByProductId(id);
  return { product: serializeProduct(row, variantRows) };
}

function assertOwner(row, userId) {
  if (row.user_id !== userId) {
    throw new AppError(
      "You do not have permission to modify this product",
      403,
      "FORBIDDEN"
    );
  }
}

async function updateProduct(productId, userId, body) {
  const existing = await productModel.findProductById(productId);
  if (!existing) {
    throw new AppError("Product not found", 404, "NOT_FOUND");
  }
  assertOwner(existing, userId);

  const hasVariantsKey = Object.prototype.hasOwnProperty.call(body, "variants");

  const patch = {};
  if (body.title !== undefined) {
    patch.title = body.title;
  }
  if (body.description !== undefined) {
    patch.description = body.description;
  }
  if (body.price !== undefined) {
    patch.price = body.price;
  }
  if (body.category_id !== undefined) {
    patch.category_id = body.category_id;
  }

  const hasProductPatch = Object.keys(patch).length > 0;

  if (!hasProductPatch && !hasVariantsKey) {
    throw new AppError(
      "At least one product field or variants is required to update",
      400,
      "VALIDATION_ERROR"
    );
  }

  let normalizedVariants = null;
  if (hasVariantsKey) {
    normalizedVariants = normalizeVariantsInput(body.variants);
  }

  try {
    if (hasVariantsKey) {
      await withTransaction(async (client) => {
        if (hasProductPatch) {
          const updated = await productModel.updateProduct(
            productId,
            patch,
            client
          );
          if (!updated) {
            throw new AppError("Product not found", 404, "NOT_FOUND");
          }
        }
        await variantModel.deleteVariantsForProduct(productId, client);
        if (normalizedVariants.length > 0) {
          await variantModel.insertVariants(
            productId,
            normalizedVariants,
            client
          );
        }
      });
    } else if (hasProductPatch) {
      const row = await productModel.updateProduct(productId, patch);
      if (!row) {
        throw new AppError("Product not found", 404, "NOT_FOUND");
      }
    }

    const row = await productModel.findProductById(productId);
    const variantRows = await variantModel.findVariantsByProductId(productId);
    return { product: serializeProduct(row, variantRows) };
  } catch (err) {
    handlePgError(err);
  }
}

async function deleteProduct(productId, userId) {
  const existing = await productModel.findProductById(productId);
  if (!existing) {
    throw new AppError("Product not found", 404, "NOT_FOUND");
  }
  assertOwner(existing, userId);
  await productModel.deleteProduct(productId);
}

module.exports = {
  createProduct,
  listProducts,
  listMyProducts,
  getProductById,
  updateProduct,
  deleteProduct,
};
