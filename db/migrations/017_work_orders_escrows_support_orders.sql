-- Allow work_orders and escrows to be linked to orders instead of swaps
ALTER TABLE work_orders ALTER COLUMN swap_id DROP NOT NULL;
ALTER TABLE work_orders ADD COLUMN order_id UUID UNIQUE REFERENCES orders (id) ON DELETE CASCADE;
ALTER TABLE work_orders ADD CONSTRAINT chk_work_orders_one_target CHECK ( (swap_id IS NOT NULL AND order_id IS NULL) OR (swap_id IS NULL AND order_id IS NOT NULL) );

ALTER TABLE escrows ALTER COLUMN swap_id DROP NOT NULL;
ALTER TABLE escrows ADD COLUMN order_id UUID UNIQUE REFERENCES orders (id) ON DELETE CASCADE;
ALTER TABLE escrows ADD CONSTRAINT chk_escrows_one_target CHECK ( (swap_id IS NOT NULL AND order_id IS NULL) OR (swap_id IS NULL AND order_id IS NOT NULL) );
