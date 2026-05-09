-- Availability flag for listings (e.g. locked when a swap is accepted into workshop).

ALTER TABLE products
  ADD COLUMN IF NOT EXISTS is_available BOOLEAN NOT NULL DEFAULT true;
