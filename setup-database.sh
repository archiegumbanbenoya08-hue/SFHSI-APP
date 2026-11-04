#!/bin/bash
# Database Setup Script for SCMCIES

echo "=================================================="
echo "SCMCIES Database Setup"
echo "=================================================="

# Check if MySQL is running
echo "Checking MySQL connection..."

# Read environment variables
DB_HOST=${DB_HOST:-localhost}
DB_USER=${DB_USER:-root}
DB_PASSWORD=${DB_PASSWORD:-}
DB_NAME="scmcies_db"

# Create database and tables
echo "Creating database and tables..."

if [ -z "$DB_PASSWORD" ]; then
    mysql -h $DB_HOST -u $DB_USER < backend-node/schema.sql
else
    mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD < backend-node/schema.sql
fi

if [ $? -eq 0 ]; then
    echo "✓ Database and tables created successfully"
else
    echo "✗ Failed to create database"
    exit 1
fi

echo "=================================================="
echo "Database setup complete!"
echo "=================================================="
