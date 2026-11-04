ALTER TABLE admin
  ADD COLUMN name VARCHAR(255) NOT NULL DEFAULT 'Administrator' AFTER email;

CREATE TABLE IF NOT EXISTS app_message (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  sender_role ENUM('admin', 'parent') NOT NULL,
  sender_id INT NOT NULL,
  sender_email VARCHAR(255) NOT NULL,
  receiver_role ENUM('admin', 'parent') NOT NULL,
  receiver_id INT NOT NULL,
  receiver_email VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_message_conversation (sender_role, sender_id, receiver_role, receiver_id, created_at),
  INDEX idx_message_reverse (receiver_role, receiver_id, sender_role, sender_id, created_at)
);
