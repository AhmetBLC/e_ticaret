-- Customer Trust: Reviews & Ratings
CREATE TABLE IF NOT EXISTS product_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(product_id, user_id) -- One review per user per product
);

-- Guest Checkout & Tracking
ALTER TABLE orders 
  ADD COLUMN IF NOT EXISTS guest_tracking_code VARCHAR(32) UNIQUE;

-- Workshop Costing / Service Fees
ALTER TABLE work_orders 
  ADD COLUMN IF NOT EXISTS service_fee DECIMAL(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS inspection_cost DECIMAL(10,2) DEFAULT 0;

-- RMA: Returns
CREATE TABLE IF NOT EXISTS return_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  status VARCHAR(20) DEFAULT 'PENDING', -- 'PENDING', 'APPROVED', 'REJECTED', 'COMPLETED'
  image_url TEXT,
  admin_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
