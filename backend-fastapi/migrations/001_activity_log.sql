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
