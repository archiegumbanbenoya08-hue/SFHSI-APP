# SCMCIES Setup

The current setup uses local Supabase (PostgreSQL + pgvector), the Node.js
attendance API, and the FastAPI service used by Flutter.

## Prerequisites

- Docker Desktop installed and running
- Node.js and npm
- Python 3.10+
- Existing MySQL database available only if you intend to migrate its data

## Start the application

From the repository root, follow [SUPABASE_LOCAL_SETUP.md](./SUPABASE_LOCAL_SETUP.md)
to start Supabase, configure the backends, and optionally copy data from MySQL.
Once the environment files contain unique credentials and matching JWT secrets,
run `setup-and-run.ps1` or `setup-and-run.bat` to start the local services.

The older XAMPP/MySQL instructions in the repository describe the legacy
database setup. They are not used by the current application backends.
