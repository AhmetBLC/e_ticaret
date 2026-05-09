-- Payment records — simulates Iyzico/Stripe virtual POS.
-- Each payment maps to an order OR a swap escrow transaction.

CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders (id) ON DELETE SET NULL,
  swap_id UUID REFERENCES swaps (id) ON DELETE SET NULL,
  amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  currency VARCHAR(3) NOT NULL DEFAULT 'TRY',
  status VARCHAR(32) NOT NULL CHECK (status IN (
    'PENDING',
    'AWAITING_3DS',
    'PAID',
    'HELD',
    'RELEASED',
    'REFUNDED',
    'FAILED'
  )),
  payment_method VARCHAR(32) NOT NULL DEFAULT 'CARD',
  card_last_four VARCHAR(4),
  card_brand VARCHAR(20),
  provider_ref VARCHAR(255),
  three_ds_url VARCHAR(1000),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments (user_id);
CREATE INDEX IF NOT EXISTS idx_payments_order_id ON payments (order_id);
CREATE INDEX IF NOT EXISTS idx_payments_swap_id ON payments (swap_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments (status);
