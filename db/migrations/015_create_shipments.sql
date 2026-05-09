-- Shipment / cargo tracking — simulates third-party logistics API.

CREATE TABLE IF NOT EXISTS shipments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders (id) ON DELETE SET NULL,
  swap_id UUID REFERENCES swaps (id) ON DELETE SET NULL,
  sender_user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  receiver_user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  sender_address_id UUID REFERENCES addresses (id) ON DELETE SET NULL,
  receiver_address_id UUID REFERENCES addresses (id) ON DELETE SET NULL,
  tracking_number VARCHAR(64) NOT NULL UNIQUE,
  barcode VARCHAR(128),
  carrier VARCHAR(50) NOT NULL DEFAULT 'SimKargo',
  status VARCHAR(32) NOT NULL CHECK (status IN (
    'LABEL_CREATED',
    'PICKED_UP',
    'IN_TRANSIT',
    'OUT_FOR_DELIVERY',
    'DELIVERED',
    'RETURNED'
  )),
  estimated_delivery DATE,
  weight_kg NUMERIC(6, 2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_shipments_order_id ON shipments (order_id);
CREATE INDEX IF NOT EXISTS idx_shipments_swap_id ON shipments (swap_id);
CREATE INDEX IF NOT EXISTS idx_shipments_tracking ON shipments (tracking_number);
CREATE INDEX IF NOT EXISTS idx_shipments_status ON shipments (status);
