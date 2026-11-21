# Local Supabase and PostgreSQL migration

This project runs Supabase locally in Docker. Its local PostgreSQL database
uses the `vector` extension for 128-dimensional face embeddings. Both backend
services now connect to that database; Flutter continues to call FastAPI.

## 1. Start local Supabase

Install and launch Docker Desktop, then from the repository root run:

```powershell
npx --yes supabase start
npx --yes supabase status
```

The local database listens on `localhost:54322`, and Supabase Studio is at
`http://localhost:54323`. The checked-in migration creates the application
tables and enables pgvector. Local Supabase uses the default database password
`postgres`; use the connection string printed by `supabase status` if you
changed it. This project has the Supabase Data API disabled; its backends
connect directly to PostgreSQL.

## 2. Configure and install the backends

Create local environment files without replacing any existing files:

```powershell
if (!(Test-Path backend-node\.env)) {
  Copy-Item backend-node\.env.example backend-node\.env
}
if (!(Test-Path backend-fastapi\.env)) {
  Copy-Item backend-fastapi\.env.example backend-fastapi\.env
}
```

Set strong, unique values for `JWT_ADMIN_SECRET`, `JWT_PARENT_SECRET`, and
`DEVICE_API_KEY` in `backend-node\.env`. Copy the exact same JWT secrets into
`backend-fastapi\.env`. Configure the desired admin and parent account values
before creating any accounts. If either `.env` file already exists, add or
update `DATABASE_URL` rather than replacing that file. Both example files
default to the local Supabase connection:

```text
postgresql://postgres:postgres@localhost:54322/postgres?sslmode=disable
```

Install dependencies and seed the initial accounts:

```powershell
Push-Location backend-node
npm install
Pop-Location

Push-Location backend-fastapi
python -m pip install -r requirements.txt
Pop-Location
```

Run the services in separate terminals:

```powershell
Push-Location backend-node
npm start
```

```powershell
Push-Location backend-fastapi
python -m uvicorn main:app --host 0.0.0.0 --port 8001
```

Keep the MySQL server available until the migration is complete. Once the app
has been verified against PostgreSQL, MySQL can be stopped; it is no longer
used by either runtime backend.

## 3. Migrated legacy SCMCIES data

The available XAMPP MariaDB database was `scmcies`, with legacy `users` and
`students` tables. Its 4 user rows and 4 student rows were copied and verified
in Supabase as `legacy_scmcies.users` and `legacy_scmcies.students`. The
original columns and values are preserved there; this legacy structure is not
the app's normalized `public.admin`, `public.parent`, and `public.student`
schema, so the import does not automatically populate those app tables.

The source `students.face_data` values were all empty, so no face embeddings
could be derived. The `face_embedding` pgvector column is present, and the
`vector` extension is enabled.

The migration script is `scripts\migrate_legacy_scmcies.py`. It reads the
legacy source from `127.0.0.1:3307` by default, takes `DATABASE_URL` from
`backend-node\.env`, and refuses to write if either target table is non-empty.
Use its dry run before `--apply`; do not clear the target tables to repeat an
import. The recovered MariaDB source was a temporary copy; start that source
on port 3307 before rerunning the script.

Only `scmcies` was selected for transfer. No SQLite database file or path was
available, and other MySQL databases were not included. The separate
`scripts\migrate_mysql_to_supabase.py` is for a different, normalized source
schema and should not be used for this legacy `scmcies` database.
