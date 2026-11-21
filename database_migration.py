#!/usr/bin/env python3
"""
Legacy SQLite/MySQL conversion menu. For migration to local Supabase, use
scripts/migrate_mysql_to_supabase.py instead.
"""

import os
import sys
import sqlite3
import subprocess
from datetime import datetime
from pathlib import Path

def export_sqlite_to_sql(db_path: str, output_file: str) -> bool:
    """Export SQLite database to SQL file"""
    try:
        print(f"🔄 Exporting SQLite database: {db_path}")
        
        # Use sqlite3 to dump database
        result = subprocess.run(
            [sys.executable, "-m", "sqlite3", db_path, ".dump"],
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            print(f"❌ Error exporting SQLite: {result.stderr}")
            return False
        
        # Write to file
        with open(output_file, 'w') as f:
            f.write(result.stdout)
        
        print(f"✅ SQLite exported to: {output_file}")
        return True
        
    except Exception as e:
        print(f"❌ Export error: {e}")
        return False

def backup_database(source_file: str) -> bool:
    """Create a backup of database file"""
    try:
        if not os.path.exists(source_file):
            print(f"❌ File not found: {source_file}")
            return False
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_file = f"{source_file}.backup_{timestamp}"
        
        with open(source_file, 'rb') as src:
            with open(backup_file, 'wb') as dst:
                dst.write(src.read())
        
        print(f"✅ Backup created: {backup_file}")
        return True
        
    except Exception as e:
        print(f"❌ Backup error: {e}")
        return False

def validate_sqlite_db(db_path: str) -> bool:
    """Validate SQLite database integrity"""
    try:
        print(f"🔍 Validating SQLite database: {db_path}")
        
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Check tables
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = cursor.fetchall()
        
        if not tables:
            print("❌ No tables found in database")
            conn.close()
            return False
        
        print(f"✅ Found {len(tables)} tables:")
        for table in tables:
            cursor.execute(f"SELECT COUNT(*) FROM {table[0]};")
            count = cursor.fetchone()[0]
            print(f"   - {table[0]}: {count} records")
        
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Validation error: {e}")
        return False

def get_mysql_connection_string(host: str = "localhost", 
                                user: str = "root", 
                                password: str = "",
                                database: str = "scmcies") -> str:
    """Generate MySQL connection string"""
    if password:
        return f"mysql+pymysql://{user}:{password}@{host}/{database}"
    else:
        return f"mysql+pymysql://{user}@{host}/{database}"

def print_migration_guide():
    """Print step-by-step migration guide"""
    guide = """
╔════════════════════════════════════════════════════════════════╗
║        SCMCIES Database Migration Guide                         ║
╚════════════════════════════════════════════════════════════════╝

📋 SQLite → MySQL Migration Steps:

1️⃣  START XAMPP
   - Open XAMPP Control Panel
   - Start Apache and MySQL

2️⃣  CREATE MYSQL DATABASE
   - Open phpMyAdmin: http://localhost/phpmyadmin
   - Create new database: "scmcies"

3️⃣  IMPORT SQL DUMP
   - Go to Import tab in phpMyAdmin
   - Select: scmcies_mysql_dump.sql
   - Click "Go"

4️⃣  UPDATE BACKEND CONFIGURATION
   - Edit: backend/.env
   - Change DATABASE_URL:
   
   FROM: DATABASE_URL=sqlite:///./scmcies.db
   TO:   DATABASE_URL=mysql+pymysql://root@localhost/scmcies

5️⃣  INSTALL MYSQL DRIVER
   - Run: pip install pymysql
   - In: backend/ directory

6️⃣  RESTART BACKEND
   - Stop backend (Ctrl+C)
   - Run: run.bat or run.sh again
   - Backend now uses MySQL!

✅ VERIFICATION:
   - Check API docs: http://localhost:8000/docs
   - Test login endpoint with default credentials
   - Check phpMyAdmin for data updates

════════════════════════════════════════════════════════════════

🔄 MySQL → SQLite (Backup):

1. Export MySQL to SQL:
   mysqldump -u root scmcies > scmcies_export.sql

2. Import to SQLite:
   sqlite3 scmcies.db < scmcies_export.sql

════════════════════════════════════════════════════════════════

🔐 Default Database Credentials:

MySQL (XAMPP):
  Host: localhost
  User: root
  Password: (empty)
  Database: scmcies
  Port: 3306

Connection String:
  mysql+pymysql://root@localhost/scmcies

════════════════════════════════════════════════════════════════

📚 Files You Need:

✅ scmcies_mysql_dump.sql  - Main database dump
✅ XAMPP_MYSQL_SETUP.md     - Detailed setup guide
✅ INTEGRATION_GUIDE.md     - Full integration guide
✅ backend/.env             - Backend configuration

════════════════════════════════════════════════════════════════

💡 Tips:

• Always backup before migrating
• Test with default credentials first
• Update passwordhashes if needed
• Keep SQLite copy as backup
• Monitor logs for errors

════════════════════════════════════════════════════════════════
"""
    print(guide)

def main():
    """Main execution"""
    print("╔════════════════════════════════════════════════════════════════╗")
    print("║     SCMCIES Database Migration Tool                             ║")
    print("╚════════════════════════════════════════════════════════════════╝\n")
    
    # Get script directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    sqlite_db = os.path.join(script_dir, "backend", "scmcies.db")
    sql_dump = os.path.join(script_dir, "scmcies_export.sql")
    
    print("\n📍 Paths:")
    print(f"   SQLite DB: {sqlite_db}")
    print(f"   SQL Export: {sql_dump}")
    
    # Menu
    print("\n🔧 Available Options:")
    print("   1. Validate SQLite database")
    print("   2. Backup SQLite database")
    print("   3. Export SQLite to SQL file")
    print("   4. Show MySQL credentials")
    print("   5. Show migration guide")
    print("   6. Run all validations")
    print("   0. Exit")
    
    choice = input("\n👉 Select option (0-6): ").strip()
    
    if choice == "1":
        validate_sqlite_db(sqlite_db)
        
    elif choice == "2":
        if os.path.exists(sqlite_db):
            backup_database(sqlite_db)
        else:
            print(f"❌ SQLite database not found: {sqlite_db}")
    
    elif choice == "3":
        if os.path.exists(sqlite_db):
            export_sqlite_to_sql(sqlite_db, sql_dump)
        else:
            print(f"❌ SQLite database not found: {sqlite_db}")
    
    elif choice == "4":
        print("\n🔐 MySQL Default Credentials (XAMPP):")
        print("   Host: localhost")
        print("   Port: 3306")
        print("   User: root")
        print("   Password: (empty)")
        print("   Database: scmcies")
        print("\nConnection String:")
        print(f"   {get_mysql_connection_string()}")
    
    elif choice == "5":
        print_migration_guide()
    
    elif choice == "6":
        print("\n🔄 Running all validations...\n")
        
        if os.path.exists(sqlite_db):
            backup_database(sqlite_db)
            print()
            validate_sqlite_db(sqlite_db)
            print()
            export_sqlite_to_sql(sqlite_db, sql_dump)
        else:
            print(f"❌ SQLite database not found at: {sqlite_db}")
        
        print_migration_guide()
    
    elif choice == "0":
        print("\n👋 Goodbye!")
    
    else:
        print("❌ Invalid option")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⏹️  Operation cancelled")
    except Exception as e:
        print(f"\n❌ Error: {e}")
