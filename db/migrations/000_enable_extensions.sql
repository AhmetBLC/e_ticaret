-- Enable pgcrypto for gen_random_uuid() if on PostgreSQL < 13
-- On RDS, this is generally allowed for the master user.
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
