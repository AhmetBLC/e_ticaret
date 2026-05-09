-- Variant SKUs per product (e.g. Size=M, Color=Red). Requires `products`.

CREATE TABLE IF NOT EXISTS product_variants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products (id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  value VARCHAR(255) NOT NULL,
  price NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
  stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
  UNIQUE (product_id, name, value)
);

CREATE INDEX IF NOT EXISTS idx_product_variants_product_id ON product_variants (product_id);
