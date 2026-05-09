-- Allow REFUNDED when workshop rejects a swap (held amount returned).

ALTER TABLE escrows DROP CONSTRAINT IF EXISTS escrows_status_check;

ALTER TABLE escrows
  ADD CONSTRAINT escrows_status_check
  CHECK (status IN ('HELD', 'RELEASED', 'REFUNDED'));
