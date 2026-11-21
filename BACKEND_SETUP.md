# Backend Setup

## Services

- `backend-node`: attendance API and email notifications on port 8000
- `backend-fastapi`: Flutter account, student, messaging, and activity API on
  port 8001
- Local Supabase PostgreSQL: database on port 54322, Studio on port 54323

Both backends use the same `DATABASE_URL` and matching
`JWT_ADMIN_SECRET`/`JWT_PARENT_SECRET` values. The Node backend additionally
requires `DEVICE_API_KEY`.

## Setup

Use [SUPABASE_LOCAL_SETUP.md](./SUPABASE_LOCAL_SETUP.md) for Docker, Supabase,
backend environment variables, dependency installation, optional MySQL data
migration, and service start commands.

The schema is managed in `supabase/migrations`. Do not apply the legacy MySQL
schema or migration files to the PostgreSQL database.
