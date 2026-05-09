const AppError = require("../utils/AppError");
const categoryModel = require("../models/category.model");

/**
 * Builds a nested tree structure from flat category rows.
 * Each node gets a `children` array.
 */
function buildTree(rows) {
  const map = new Map();
  const roots = [];

  // First pass: create nodes
  for (const row of rows) {
    map.set(row.id, { ...row, children: [] });
  }

  // Second pass: link parents
  for (const node of map.values()) {
    if (node.parent_id && map.has(node.parent_id)) {
      map.get(node.parent_id).children.push(node);
    } else {
      roots.push(node);
    }
  }

  return roots;
}

async function listCategories({ flat } = {}) {
  const rows = await categoryModel.findAllCategories();
  if (flat) {
    return { categories: rows };
  }
  return { categories: buildTree(rows) };
}

async function createCategory(body) {
  const { name, parent_id: parentId } = body;

  if (parentId) {
    const parent = await categoryModel.findCategoryById(parentId);
    if (!parent) {
      throw new AppError("Parent category not found", 404, "NOT_FOUND");
    }
  }

  const row = await categoryModel.insertCategory({ name, parentId });
  return { category: row };
}

async function updateCategory(id, body) {
  const existing = await categoryModel.findCategoryById(id);
  if (!existing) {
    throw new AppError("Category not found", 404, "NOT_FOUND");
  }

  if (body.parent_id) {
    if (body.parent_id === id) {
      throw new AppError(
        "A category cannot be its own parent",
        400,
        "VALIDATION_ERROR"
      );
    }
    const parent = await categoryModel.findCategoryById(body.parent_id);
    if (!parent) {
      throw new AppError("Parent category not found", 404, "NOT_FOUND");
    }
  }

  const row = await categoryModel.updateCategory(id, {
    name: body.name,
    parentId: body.parent_id,
  });
  if (!row) {
    throw new AppError("No fields to update", 400, "VALIDATION_ERROR");
  }
  return { category: row };
}

async function deleteCategory(id) {
  const existing = await categoryModel.findCategoryById(id);
  if (!existing) {
    throw new AppError("Category not found", 404, "NOT_FOUND");
  }
  await categoryModel.deleteCategory(id);
}

module.exports = {
  listCategories,
  createCategory,
  updateCategory,
  deleteCategory,
};
