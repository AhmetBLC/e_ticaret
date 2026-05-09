-- Swap proposals between two users and two products. Requires `users`, `products`.

CREATE TABLE IF NOT EXISTS swaps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  receiver_user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  product_offered_id UUID NOT NULL REFERENCES products (id) ON DELETE CASCADE,
  product_requested_id UUID NOT NULL REFERENCES products (id) ON DELETE CASCADE,
  status VARCHAR(32) NOT NULL CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED', 'WORKSHOP')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (requester_user_id <> receiver_user_id),
  CHECK (product_offered_id <> product_requested_id)
);

CREATE INDEX IF NOT EXISTS idx_swaps_requester ON swaps (requester_user_id);
CREATE INDEX IF NOT EXISTS idx_swaps_receiver ON swaps (receiver_user_id);
CREATE INDEX IF NOT EXISTS idx_swaps_status ON swaps (status);
