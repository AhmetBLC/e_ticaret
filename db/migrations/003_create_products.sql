-- Products belong to a seller (users) and optionally to one category.
-- Requires tables: users, categories.

CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(500) NOT NULL,
  description TEXT,
  price NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
  user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories (id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_products_user_id ON products (user_id);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON products (category_id);
