#!/usr/bin/env python3
"""
Database Connection Utility for db-explorer skill.

Handles connection testing and environment variable detection for PostgreSQL, MySQL, and SQLite.

Usage:
    db_connect.py --check-env                    # Check available environment variables
    db_connect.py --test                         # Test connection using env vars
    db_connect.py --test --type sqlite --database /path/to/db.sqlite
"""

import argparse
import json
import os
import subprocess
import sys
from urllib.parse import urlparse


def get_env_vars():
    """Detect available database environment variables."""
    postgres_vars = {
        'PGHOST': os.environ.get('PGHOST'),
        'PGPORT': os.environ.get('PGPORT', '5432'),
        'PGDATABASE': os.environ.get('PGDATABASE'),
        'PGUSER': os.environ.get('PGUSER'),
        'PGPASSWORD': '***' if os.environ.get('PGPASSWORD') else None,
    }
    
    mysql_vars = {
        'MYSQL_HOST': os.environ.get('MYSQL_HOST'),
        'MYSQL_TCP_PORT': os.environ.get('MYSQL_TCP_PORT', '3306'),
        'MYSQL_DATABASE': os.environ.get('MYSQL_DATABASE'),
        'MYSQL_USER': os.environ.get('MYSQL_USER'),
        'MYSQL_PWD': '***' if os.environ.get('MYSQL_PWD') else None,
    }
    
    sqlite_vars = {
        'SQLITE_DATABASE': os.environ.get('SQLITE_DATABASE'),
    }
    
    database_url = os.environ.get('DATABASE_URL')
    
    return {
        'postgres': postgres_vars,
        'mysql': mysql_vars,
        'sqlite': sqlite_vars,
        'database_url': '***' if database_url else None,
        'database_url_type': detect_url_type(database_url) if database_url else None,
    }


def detect_url_type(url):
    """Detect database type from connection URL."""
    if not url:
        return None
    parsed = urlparse(url)
    scheme = parsed.scheme.lower()
    if scheme in ('postgres', 'postgresql'):
        return 'postgres'
    elif scheme in ('mysql', 'mysql+pymysql'):
        return 'mysql'
    elif scheme in ('sqlite', 'sqlite3'):
        return 'sqlite'
    return None


def parse_database_url(url):
    """Parse DATABASE_URL into connection parameters."""
    parsed = urlparse(url)
    return {
        'host': parsed.hostname or 'localhost',
        'port': str(parsed.port) if parsed.port else None,
        'database': parsed.path.lstrip('/') if parsed.path else None,
        'user': parsed.username,
        'password': parsed.password,
    }


def detect_database_type():
    """Auto-detect which database type is configured."""
    env_vars = get_env_vars()
    
    # Check DATABASE_URL first
    if env_vars['database_url']:
        return env_vars['database_url_type']
    
    # Check PostgreSQL vars
    pg_configured = env_vars['postgres']['PGDATABASE'] or env_vars['postgres']['PGHOST']
    
    # Check MySQL vars
    mysql_configured = env_vars['mysql']['MYSQL_DATABASE'] or env_vars['mysql']['MYSQL_HOST']
    
    # Check SQLite vars
    sqlite_configured = env_vars['sqlite']['SQLITE_DATABASE']
    
    configured = [t for t, c in [('postgres', pg_configured), ('mysql', mysql_configured), ('sqlite', sqlite_configured)] if c]
    
    if len(configured) == 1:
        return configured[0]
    elif len(configured) > 1:
        return 'multiple'  # User needs to specify
    
    return None


def get_connection_params(db_type, args):
    """Get connection parameters from args or environment."""
    # Check for DATABASE_URL first
    database_url = os.environ.get('DATABASE_URL')
    if database_url and detect_url_type(database_url) == db_type:
        params = parse_database_url(database_url)
        # Fill in defaults
        if db_type == 'postgres':
            params['port'] = params['port'] or '5432'
        elif db_type == 'mysql':
            params['port'] = params['port'] or '3306'
        return params
    
    if db_type == 'postgres':
        return {
            'host': args.host or os.environ.get('PGHOST', 'localhost'),
            'port': args.port or os.environ.get('PGPORT', '5432'),
            'database': args.database or os.environ.get('PGDATABASE'),
            'user': args.user or os.environ.get('PGUSER'),
            'password': args.password or os.environ.get('PGPASSWORD'),
        }
    elif db_type == 'mysql':
        return {
            'host': args.host or os.environ.get('MYSQL_HOST', 'localhost'),
            'port': args.port or os.environ.get('MYSQL_TCP_PORT', '3306'),
            'database': args.database or os.environ.get('MYSQL_DATABASE'),
            'user': args.user or os.environ.get('MYSQL_USER'),
            'password': args.password or os.environ.get('MYSQL_PWD'),
        }
    else:  # sqlite
        return {
            'database': args.database or os.environ.get('SQLITE_DATABASE'),
        }


def test_postgres_connection(params):
    """Test PostgreSQL connection using psql."""
    env = os.environ.copy()
    env['PGPASSWORD'] = params['password'] or ''
    
    cmd = [
        'psql',
        '-h', params['host'],
        '-p', params['port'],
        '-U', params['user'],
        '-d', params['database'],
        '-c', 'SELECT 1;',
        '--no-psqlrc',
        '-q'
    ]
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            env=env,
            timeout=10
        )
        if result.returncode == 0:
            return True, "Connection successful"
        else:
            return False, result.stderr.strip()
    except subprocess.TimeoutExpired:
        return False, "Connection timed out"
    except FileNotFoundError:
        return False, "psql client not found. Please install PostgreSQL client."


def test_mysql_connection(params):
    """Test MySQL connection using mysql client."""
    cmd = [
        'mysql',
        '-h', params['host'],
        '-P', params['port'],
        '-u', params['user'],
        f"-p{params['password']}" if params['password'] else '--skip-password',
        '-D', params['database'],
        '-e', 'SELECT 1;',
        '--batch',
        '--silent'
    ]
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode == 0:
            return True, "Connection successful"
        else:
            return False, result.stderr.strip()
    except subprocess.TimeoutExpired:
        return False, "Connection timed out"
    except FileNotFoundError:
        return False, "mysql client not found. Please install MySQL client."


def test_sqlite_connection(params):
    """Test SQLite connection."""
    db_path = params['database']
    
    if not db_path:
        return False, "No database path provided"
    
    if not os.path.exists(db_path):
        return False, f"Database file not found: {db_path}"
    
    cmd = ['sqlite3', db_path, 'SELECT 1;']
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode == 0:
            return True, "Connection successful"
        else:
            return False, result.stderr.strip()
    except subprocess.TimeoutExpired:
        return False, "Connection timed out"
    except FileNotFoundError:
        return False, "sqlite3 not found. Please install SQLite."


def check_env():
    """Display detected environment variables."""
    env_vars = get_env_vars()
    detected_type = detect_database_type()
    
    print("=== Database Environment Variables ===\n")
    
    print("PostgreSQL:")
    for key, value in env_vars['postgres'].items():
        status = "set" if value and value != '5432' else ("default" if value else "not set")
        display = value if value else "-"
        print(f"  {key}: {display} ({status})")
    
    print("\nMySQL:")
    for key, value in env_vars['mysql'].items():
        status = "set" if value and value != '3306' else ("default" if value else "not set")
        display = value if value else "-"
        print(f"  {key}: {display} ({status})")
    
    print("\nSQLite:")
    for key, value in env_vars['sqlite'].items():
        status = "set" if value else "not set"
        display = value if value else "-"
        print(f"  {key}: {display} ({status})")
    
    print(f"\nDATABASE_URL: {env_vars['database_url'] or 'not set'}")
    if env_vars['database_url_type']:
        print(f"  Detected type: {env_vars['database_url_type']}")
    
    print(f"\nAuto-detected database type: {detected_type or 'none'}")
    
    if detected_type == 'multiple':
        print("  Note: Multiple databases configured. Please specify --type")
    elif not detected_type:
        print("  Note: No database credentials detected. Please set environment variables or provide connection parameters.")
    
    return env_vars


def main():
    parser = argparse.ArgumentParser(description='Database connection utility')
    parser.add_argument('--check-env', action='store_true', help='Check environment variables')
    parser.add_argument('--test', action='store_true', help='Test database connection')
    parser.add_argument('--type', choices=['postgres', 'mysql', 'sqlite'], help='Database type')
    parser.add_argument('--host', help='Database host')
    parser.add_argument('--port', help='Database port')
    parser.add_argument('--database', help='Database name')
    parser.add_argument('--user', help='Database user')
    parser.add_argument('--password', help='Database password')
    parser.add_argument('--json', action='store_true', help='Output as JSON')
    
    args = parser.parse_args()
    
    if args.check_env:
        env_vars = check_env()
        if args.json:
            # Remove masked passwords for JSON output
            output = {
                'postgres_configured': bool(env_vars['postgres']['PGDATABASE']),
                'mysql_configured': bool(env_vars['mysql']['MYSQL_DATABASE']),
                'sqlite_configured': bool(env_vars['sqlite']['SQLITE_DATABASE']),
                'database_url_configured': bool(env_vars['database_url']),
                'detected_type': detect_database_type(),
            }
            print(json.dumps(output, indent=2))
        return 0
    
    if args.test:
        db_type = args.type or detect_database_type()
        
        if not db_type:
            print("Error: Could not detect database type. Please specify --type postgres, --type mysql, or --type sqlite")
            return 1
        
        if db_type == 'multiple':
            print("Error: Multiple databases configured. Please specify --type")
            return 1
        
        params = get_connection_params(db_type, args)
        
        # Validate required params (sqlite only needs database)
        if db_type == 'sqlite':
            if not params.get('database'):
                print("Error: Missing database path for SQLite")
                return 1
        else:
            missing = [k for k, v in params.items() if not v and k != 'password']
            if missing:
                print(f"Error: Missing required parameters: {', '.join(missing)}")
                return 1
        
        if db_type == 'sqlite':
            print(f"Testing {db_type} connection to {params['database']}...")
        else:
            print(f"Testing {db_type} connection to {params['host']}:{params['port']}/{params['database']}...")
        
        if db_type == 'postgres':
            success, message = test_postgres_connection(params)
        elif db_type == 'mysql':
            success, message = test_mysql_connection(params)
        else:
            success, message = test_sqlite_connection(params)
        
        if args.json:
            print(json.dumps({
                'success': success,
                'message': message,
                'type': db_type,
                'host': params['host'],
                'port': params['port'],
                'database': params['database'],
            }, indent=2))
        else:
            if success:
                print(f"✅ {message}")
            else:
                print(f"❌ {message}")
        
        return 0 if success else 1
    
    parser.print_help()
    return 0


if __name__ == '__main__':
    sys.exit(main())
