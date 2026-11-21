CREATE TABLE IF NOT EXISTS pending_parent_signup (
  email VARCHAR(255) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  verification_code_hash VARCHAR(60) NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  last_sent_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  attempts_remaining SMALLINT NOT NULL DEFAULT 5
    CHECK (attempts_remaining BETWEEN 0 AND 5)
);

ALTER TABLE pending_parent_signup ENABLE ROW LEVEL SECURITY;
