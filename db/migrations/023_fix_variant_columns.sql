-- Rename columns in product_variants to match the service layer expectations
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_variants' AND column_name = 'price') THEN
    ALTER TABLE product_variants RENAME COLUMN price TO price_override;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'product_variants' AND column_name = 'stock') THEN
    ALTER TABLE product_variants RENAME COLUMN stock TO stock_quantity;
  END IF;
END $$;
