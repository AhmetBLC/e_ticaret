-- Make 'value' column nullable or drop it if it's deprecated
-- In recent versions, we use 'name' instead of 'value' for variants.
ALTER TABLE product_variants ALTER COLUMN value DROP NOT NULL;

-- Also ensure 'name' column exists
ALTER TABLE product_variants ADD COLUMN IF NOT EXISTS name VARCHAR(255);
