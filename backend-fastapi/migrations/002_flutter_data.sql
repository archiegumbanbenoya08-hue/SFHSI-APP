-- LEGACY MYSQL MIGRATION. Supabase schema changes belong in supabase/migrations.
ALTER TABLE admin
  ADD COLUMN name VARCHAR(255) NOT NULL DEFAULT 'Administrator' AFTER email;
