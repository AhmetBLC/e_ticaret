const { query } = require("../config/database");

const CATEGORY_SELECT = "id, name, parent_id";

async function findAllCategories() {
  const r = await query(
    `SELECT ${CATEGORY_SELECT} FROM categories ORDER BY name ASC`
  );
  return r.rows;
}

async function findCategoryById(id) {
  const r = await query(
    `SELECT ${CATEGORY_SELECT} FROM categories WHERE id = $1`,
    [id]
  );
  return r.rows[0] || null;
}

async function insertCategory({ name, parentId }) {
  const r = await query(
    `INSERT INTO categories (name, parent_id)
     VALUES ($1, $2)
     RETURNING ${CATEGORY_SELECT}`,
    [name, parentId || null]
  );
  return r.rows[0];
}

async function updateCategory(id, { name, parentId }) {
  const sets = [];
  const values = [];
  let i = 1;
  if (name !== undefined) {
    sets.push(`name = $${i++}`);
    values.push(name);
  }
  if (parentId !== undefined) {
    sets.push(`parent_id = $${i++}`);
    values.push(parentId || null);
  }
  if (sets.length === 0) {
    return null;
  }
  values.push(id);
  const sql = `
    UPDATE categories
    SET ${sets.join(", ")}
    WHERE id = $${i}
    RETURNING ${CATEGORY_SELECT}
  `;
  const r = await query(sql, values);
  return r.rows[0] || null;
}

async function deleteCategory(id) {
  const r = await query(
    "DELETE FROM categories WHERE id = $1 RETURNING id",
    [id]
  );
  return r.rowCount > 0;
}

module.exports = {
  findAllCategories,
  findCategoryById,
  insertCategory,
  updateCategory,
  deleteCategory,
};
