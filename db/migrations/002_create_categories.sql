-- Nested category tree: root rows have parent_id IS NULL.
-- Self-reference: parent_id -> categories(id) ON DELETE SET NULL (re-parent or orphan children handled by app / future migration).

CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  parent_id UUID REFERENCES categories (id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON categories (parent_id);
