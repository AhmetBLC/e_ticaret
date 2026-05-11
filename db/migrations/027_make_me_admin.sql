-- Update user role to ADMIN
-- Buradaki mail adresini kendi kayıt olduğunuz mail adresiyle değiştirin!
UPDATE users SET role = 'admin' WHERE email = 'admin@gmail.com';
