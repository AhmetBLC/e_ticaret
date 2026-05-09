-- Holds price-difference funds for swaps in workshop. Requires `swaps`.

CREATE TABLE IF NOT EXISTS escrows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  swap_id UUID NOT NULL UNIQUE REFERENCES swaps (id) ON DELETE CASCADE,
  amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  status VARCHAR(32) NOT NULL CHECK (status IN ('HELD', 'RELEASED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_escrows_swap_id ON escrows (swap_id);
CREATE INDEX IF NOT EXISTS idx_escrows_status ON escrows (status);

-- Backfill HELD escrows for swaps already in WORKSHOP with a listing price difference.
INSERT INTO escrows (swap_id, amount, status)
SELECT
  s.id,
  ABS(p1.price - p2.price),
  'HELD'
FROM swaps s
JOIN products p1 ON p1.id = s.product_offered_id
JOIN products p2 ON p2.id = s.product_requested_id
WHERE s.status = 'WORKSHOP'
  AND ABS(p1.price - p2.price) > 0
ON CONFLICT (swap_id) DO NOTHING;
