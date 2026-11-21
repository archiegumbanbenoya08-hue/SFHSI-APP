-- LEGACY MYSQL SOURCE SCHEMA. Current application schema is managed by
-- supabase/migrations; do not apply this file to the local Supabase database.
CREATE DATABASE IF NOT EXISTS scmcies_db;
USE scmcies_db;

CREATE TABLE IF NOT EXISTS admin (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL DEFAULT 'Administrator',
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS parent (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS student (
  id INT AUTO_INCREMENT PRIMARY KEY,
  student_id VARCHAR(50) NOT NULL UNIQUE,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  grade_level VARCHAR(20),
  section VARCHAR(20),
  parent_id INT NOT NULL,
  parent_email VARCHAR(255) NOT NULL,
  face_encoding LONGTEXT,
  image_path VARCHAR(255),
  status VARCHAR(20) DEFAULT 'NOT_IN_CAMPUS',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (parent_id) REFERENCES parent(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS entry_exit_log (
  id INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  event_type ENUM('ENTRY', 'EXIT') NOT NULL,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  location VARCHAR(255) DEFAULT 'Main Gate',
  confidence_score DECIMAL(5, 2),
  FOREIGN KEY (student_id) REFERENCES student(id) ON DELETE CASCADE,
  INDEX (student_id, timestamp DESC)
);

CREATE TABLE IF NOT EXISTS activity_log (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  actor_role ENUM('admin', 'parent', 'system') NOT NULL,
  actor_id INT NULL,
  actor_email VARCHAR(255) NULL,
  action VARCHAR(100) NOT NULL,
  entity_type VARCHAR(50) NULL,
  entity_id VARCHAR(64) NULL,
  parent_id INT NULL,
  details JSON NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_activity_actor_time (actor_role, actor_id, created_at),
  INDEX idx_activity_parent_time (parent_id, created_at),
  INDEX idx_activity_entity (entity_type, entity_id),
  CONSTRAINT fk_activity_parent
    FOREIGN KEY (parent_id) REFERENCES parent(id) ON DELETE SET NULL
);

CREATE INDEX idx_email ON admin(email);
CREATE INDEX idx_parent_email ON parent(email);
CREATE INDEX idx_student_id ON student(student_id);
