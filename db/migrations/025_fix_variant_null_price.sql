-- Make price_override and stock_quantity nullable for product_variants
-- This prevents crashes when variant price/stock is not explicitly provided.
ALTER TABLE product_variants ALTER COLUMN price_override DROP NOT NULL;
ALTER TABLE product_variants ALTER COLUMN stock_quantity DROP NOT NULL;

-- Default stock_quantity to 0 if not provided
ALTER TABLE product_variants ALTER COLUMN stock_quantity SET DEFAULT 0;
