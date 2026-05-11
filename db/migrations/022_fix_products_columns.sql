-- Add missing columns to products table if they don't exist
ALTER TABLE products 
  ADD COLUMN IF NOT EXISTS image_url TEXT,
  ADD COLUMN IF NOT EXISTS city VARCHAR(100),
  ADD COLUMN IF NOT EXISTS district VARCHAR(100),
  ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT TRUE;

-- Ensure indexes for performance
CREATE INDEX IF NOT EXISTS idx_products_city ON products(city);
