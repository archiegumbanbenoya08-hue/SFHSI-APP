CREATE TABLE IF NOT EXISTS public.push_device_token (
  fcm_installation_id TEXT PRIMARY KEY,
  user_role VARCHAR(6) NOT NULL CHECK (user_role IN ('admin', 'parent')),
  user_id INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_push_device_token_user
  ON public.push_device_token (user_role, user_id);

ALTER TABLE public.push_device_token ENABLE ROW LEVEL SECURITY;
