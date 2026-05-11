-- Force update user role to ADMIN
-- Bu dosya ismi yeni olduğu için kesinlikle çalışacaktır.
UPDATE users SET role = 'ADMIN' WHERE email = 'admin@gmail.com';
