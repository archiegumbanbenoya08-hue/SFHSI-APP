#!/bin/bash
# Start the local Supabase PostgreSQL database for SCMCIES.

echo "=================================================="
echo "SCMCIES Database Setup"
echo "=================================================="

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker Desktop is required. Install and start it, then retry."
    exit 1
fi

if ! npx --yes supabase start; then
    echo "✗ Failed to start local Supabase"
    exit 1
fi

echo "=================================================="
echo "Supabase PostgreSQL is running at localhost:54322"
echo "=================================================="
