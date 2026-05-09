-- Workshop queue for swaps in WORKSHOP status. Requires `swaps`.

CREATE TABLE IF NOT EXISTS work_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  swap_id UUID NOT NULL UNIQUE REFERENCES swaps (id) ON DELETE CASCADE,
  status VARCHAR(32) NOT NULL CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_work_orders_status ON work_orders (status);

-- Backfill workshop queue for swaps already in WORKSHOP (e.g. before this migration).
INSERT INTO work_orders (swap_id, status)
SELECT s.id, 'PENDING'
FROM swaps s
WHERE s.status = 'WORKSHOP'
ON CONFLICT (swap_id) DO NOTHING;

-- Allow terminal / workshop lifecycle states on swaps
ALTER TABLE swaps DROP CONSTRAINT IF EXISTS swaps_status_check;

ALTER TABLE swaps ADD CONSTRAINT swaps_status_check CHECK (
  status IN (
    'PENDING',
    'ACCEPTED',
    'REJECTED',
    'WORKSHOP',
    'COMPLETED',
    'CANCELLED'
  )
);
