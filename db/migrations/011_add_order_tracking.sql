-- Cargo simulation: unique tracking number per order (set when shipped).

ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS tracking_number VARCHAR(64);

CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_tracking_number_unique
  ON orders (tracking_number)
  WHERE tracking_number IS NOT NULL;
