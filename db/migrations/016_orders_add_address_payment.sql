-- Link orders to shipping address and payment.

ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS shipping_address_id UUID REFERENCES addresses (id) ON DELETE SET NULL;

ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS payment_id UUID REFERENCES payments (id) ON DELETE SET NULL;

ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS total_amount NUMERIC(12, 2);
