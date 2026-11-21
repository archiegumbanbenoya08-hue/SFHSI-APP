# Database Setup

The application backends use PostgreSQL in local Supabase. The schema enables
the `vector` extension and stores 128-dimensional face embeddings in
`student.face_embedding`; the original face-encoding JSON text remains
available to the Mini PC client.

For Docker installation, starting Supabase, backend configuration, and data
migration instructions, see [SUPABASE_LOCAL_SETUP.md](./SUPABASE_LOCAL_SETUP.md).

## Database services

- Node.js backend: PostgreSQL via `pg` and `DATABASE_URL`.
- FastAPI backend (used by Flutter): PostgreSQL via Psycopg and `DATABASE_URL`.
- Supabase local database: `localhost:54322`; Supabase Studio:
  `http://localhost:54323`.

The Flutter code in this repository uses the FastAPI service; it does not
contain a local SQLite database implementation. The MySQL source migration
script transfers the active SCMCIES MySQL tables without changing the source.
An SQLite file was not provided, so SQLite data is not included.

## Safe migration notes

1. Keep the existing MySQL database unchanged until the PostgreSQL data has
   been checked.
2. The migration script defaults to a dry run and refuses to write into any
   non-empty target tables.
3. Run the copy only after reviewing the dry-run table counts.
4. Back up the MySQL database before beginning a production migration.
