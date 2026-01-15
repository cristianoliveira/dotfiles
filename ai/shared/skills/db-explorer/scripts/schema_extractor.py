#!/usr/bin/env python3
"""
Database Schema Extractor for db-explorer skill.

Extracts schema information from PostgreSQL, MySQL, or SQLite databases and outputs
as JSON or Markdown with Mermaid ERD diagrams.

Usage:
    schema_extractor.py --output json                    # Full schema as JSON
    schema_extractor.py --output markdown                # Full schema as Markdown
    schema_extractor.py --table users --output json      # Specific table
    schema_extractor.py --output markdown --file out.md  # Save to file
    schema_extractor.py --type sqlite --database /path/to/db.sqlite --output json
"""

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime
from urllib.parse import urlparse


def detect_database_type():
    """Auto-detect which database type is configured."""
    database_url = os.environ.get('DATABASE_URL')
    if database_url:
        parsed = urlparse(database_url)
        scheme = parsed.scheme.lower()
        if scheme in ('postgres', 'postgresql'):
            return 'postgres'
        elif scheme in ('mysql', 'mysql+pymysql'):
            return 'mysql'
        elif scheme in ('sqlite', 'sqlite3'):
            return 'sqlite'
    
    pg_configured = os.environ.get('PGDATABASE') or os.environ.get('PGHOST')
    mysql_configured = os.environ.get('MYSQL_DATABASE') or os.environ.get('MYSQL_HOST')
    sqlite_configured = os.environ.get('SQLITE_DATABASE')
    
    configured = [t for t, c in [('postgres', pg_configured), ('mysql', mysql_configured), ('sqlite', sqlite_configured)] if c]
    
    if len(configured) == 1:
        return configured[0]
    
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


def get_connection_params(db_type, args=None):
    """Get connection parameters from environment or args."""
    database_url = os.environ.get('DATABASE_URL')
    if database_url:
        params = parse_database_url(database_url)
        if db_type == 'postgres':
            params['port'] = params['port'] or '5432'
        elif db_type == 'mysql':
            params['port'] = params['port'] or '3306'
        return params
    
    if db_type == 'postgres':
        return {
            'host': os.environ.get('PGHOST', 'localhost'),
            'port': os.environ.get('PGPORT', '5432'),
            'database': os.environ.get('PGDATABASE'),
            'user': os.environ.get('PGUSER'),
            'password': os.environ.get('PGPASSWORD'),
        }
    elif db_type == 'mysql':
        return {
            'host': os.environ.get('MYSQL_HOST', 'localhost'),
            'port': os.environ.get('MYSQL_TCP_PORT', '3306'),
            'database': os.environ.get('MYSQL_DATABASE'),
            'user': os.environ.get('MYSQL_USER'),
            'password': os.environ.get('MYSQL_PWD'),
        }
    else:  # sqlite
        db_path = (args.database if args else None) or os.environ.get('SQLITE_DATABASE')
        return {
            'database': db_path,
        }


def run_postgres_query(params, query):
    """Execute a PostgreSQL query and return results as list of dicts."""
    env = os.environ.copy()
    env['PGPASSWORD'] = params['password'] or ''
    
    cmd = [
        'psql',
        '-h', params['host'],
        '-p', params['port'],
        '-U', params['user'],
        '-d', params['database'],
        '-t',  # tuples only
        '-A',  # unaligned
        '-F', '\t',  # tab separator
        '--no-psqlrc',
        '-c', query
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True, env=env, timeout=30)
    if result.returncode != 0:
        raise Exception(f"Query failed: {result.stderr}")
    
    return result.stdout.strip()


def run_mysql_query(params, query):
    """Execute a MySQL query and return results."""
    cmd = [
        'mysql',
        '-h', params['host'],
        '-P', params['port'],
        '-u', params['user'],
        f"-p{params['password']}" if params['password'] else '--skip-password',
        '-D', params['database'],
        '-N',  # no column names
        '-B',  # batch mode (tab separated)
        '-e', query
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    if result.returncode != 0:
        raise Exception(f"Query failed: {result.stderr}")
    
    return result.stdout.strip()


def run_sqlite_query(params, query):
    """Execute a SQLite query and return results."""
    cmd = [
        'sqlite3',
        '-separator', '\t',
        params['database'],
        query
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    if result.returncode != 0:
        raise Exception(f"Query failed: {result.stderr}")
    
    return result.stdout.strip()


def extract_postgres_schema(params, table_filter=None):
    """Extract schema from PostgreSQL database."""
    schema = {
        'database': params['database'],
        'type': 'postgres',
        'extracted_at': datetime.now().isoformat(),
        'tables': []
    }
    
    # Get all tables
    tables_query = """
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
    ORDER BY table_name;
    """
    
    tables_result = run_postgres_query(params, tables_query)
    table_names = [t.strip() for t in tables_result.split('\n') if t.strip()]
    
    if table_filter:
        table_names = [t for t in table_names if t == table_filter]
    
    for table_name in table_names:
        table_info = {'name': table_name, 'columns': [], 'primary_key': [], 'foreign_keys': [], 'indexes': []}
        
        # Get columns
        columns_query = f"""
        SELECT 
            c.column_name,
            c.data_type,
            c.is_nullable,
            c.column_default,
            c.character_maximum_length,
            pgd.description
        FROM information_schema.columns c
        LEFT JOIN pg_catalog.pg_statio_all_tables st ON c.table_name = st.relname
        LEFT JOIN pg_catalog.pg_description pgd ON pgd.objoid = st.relid AND pgd.objsubid = c.ordinal_position
        WHERE c.table_schema = 'public' AND c.table_name = '{table_name}'
        ORDER BY c.ordinal_position;
        """
        
        columns_result = run_postgres_query(params, columns_query)
        for line in columns_result.split('\n'):
            if not line.strip():
                continue
            parts = line.split('\t')
            if len(parts) >= 4:
                col_type = parts[1]
                if parts[4] and parts[4] != '\\N' and parts[4].isdigit():
                    col_type = f"{parts[1]}({parts[4]})"
                table_info['columns'].append({
                    'name': parts[0],
                    'type': col_type,
                    'nullable': parts[2] == 'YES',
                    'default': parts[3] if parts[3] and parts[3] != '\\N' else None,
                    'comment': parts[5] if len(parts) > 5 and parts[5] and parts[5] != '\\N' else None
                })
        
        # Get primary key
        pk_query = f"""
        SELECT kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu 
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        WHERE tc.constraint_type = 'PRIMARY KEY'
        AND tc.table_schema = 'public'
        AND tc.table_name = '{table_name}'
        ORDER BY kcu.ordinal_position;
        """
        
        pk_result = run_postgres_query(params, pk_query)
        table_info['primary_key'] = [p.strip() for p in pk_result.split('\n') if p.strip()]
        
        # Get foreign keys
        fk_query = f"""
        SELECT
            kcu.column_name,
            ccu.table_name AS foreign_table,
            ccu.column_name AS foreign_column,
            tc.constraint_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_schema = 'public'
        AND tc.table_name = '{table_name}';
        """
        
        fk_result = run_postgres_query(params, fk_query)
        for line in fk_result.split('\n'):
            if not line.strip():
                continue
            parts = line.split('\t')
            if len(parts) >= 4:
                table_info['foreign_keys'].append({
                    'column': parts[0],
                    'references_table': parts[1],
                    'references_column': parts[2],
                    'constraint_name': parts[3]
                })
        
        # Get indexes
        idx_query = f"""
        SELECT
            i.relname AS index_name,
            array_to_string(array_agg(a.attname ORDER BY array_position(ix.indkey, a.attnum)), ', ') AS columns,
            ix.indisunique AS is_unique,
            ix.indisprimary AS is_primary
        FROM pg_class t
        JOIN pg_index ix ON t.oid = ix.indrelid
        JOIN pg_class i ON i.oid = ix.indexrelid
        JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(ix.indkey)
        WHERE t.relkind = 'r' AND t.relname = '{table_name}'
        GROUP BY i.relname, ix.indisunique, ix.indisprimary;
        """
        
        idx_result = run_postgres_query(params, idx_query)
        for line in idx_result.split('\n'):
            if not line.strip():
                continue
            parts = line.split('\t')
            if len(parts) >= 4:
                table_info['indexes'].append({
                    'name': parts[0],
                    'columns': parts[1].split(', '),
                    'unique': parts[2] == 't',
                    'primary': parts[3] == 't'
                })
        
        schema['tables'].append(table_info)
    
    return schema


def extract_mysql_schema(params, table_filter=None):
    """Extract schema from MySQL database."""
    schema = {
        'database': params['database'],
        'type': 'mysql',
        'extracted_at': datetime.now().isoformat(),
        'tables': []
    }
    
    # Get all tables
    tables_query = f"SHOW TABLES FROM {params['database']};"
    tables_result = run_mysql_query(params, tables_query)
    table_names = [t.strip() for t in tables_result.split('\n') if t.strip()]
    
    if table_filter:
        table_names = [t for t in table_names if t == table_filter]
    
    for table_name in table_names:
        table_info = {'name': table_name, 'columns': [], 'primary_key': [], 'foreign_keys': [], 'indexes': []}
        
        # Get columns
        columns_query = f"""
        SELECT 
            COLUMN_NAME,
            COLUMN_TYPE,
            IS_NULLABLE,
            COLUMN_DEFAULT,
            COLUMN_KEY,
            COLUMN_COMMENT
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = '{params['database']}' AND TABLE_NAME = '{table_name}'
        ORDER BY ORDINAL_POSITION;
        """
        
        columns_result = run_mysql_query(params, columns_query)
        for line in columns_result.split('\n'):
            if not line.strip():
                continue
            parts = line.split('\t')
            if len(parts) >= 5:
                col = {
                    'name': parts[0],
                    'type': parts[1],
                    'nullable': parts[2] == 'YES',
                    'default': parts[3] if parts[3] and parts[3] != 'NULL' else None,
                    'comment': parts[5] if len(parts) > 5 and parts[5] else None
                }
                if parts[4] == 'PRI':
                    table_info['primary_key'].append(parts[0])
                table_info['columns'].append(col)
        
        # Get foreign keys
        fk_query = f"""
        SELECT
            COLUMN_NAME,
            REFERENCED_TABLE_NAME,
            REFERENCED_COLUMN_NAME,
            CONSTRAINT_NAME
        FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
        WHERE TABLE_SCHEMA = '{params['database']}'
        AND TABLE_NAME = '{table_name}'
        AND REFERENCED_TABLE_NAME IS NOT NULL;
        """
        
        fk_result = run_mysql_query(params, fk_query)
        for line in fk_result.split('\n'):
            if not line.strip():
                continue
            parts = line.split('\t')
            if len(parts) >= 4:
                table_info['foreign_keys'].append({
                    'column': parts[0],
                    'references_table': parts[1],
                    'references_column': parts[2],
                    'constraint_name': parts[3]
                })
        
        # Get indexes
        idx_query = f"SHOW INDEX FROM {table_name};"
        idx_result = run_mysql_query(params, idx_query)
        indexes = {}
        for line in idx_result.split('\n'):
            if not line.strip():
                continue
            parts = line.split('\t')
            if len(parts) >= 5:
                idx_name = parts[2]
                col_name = parts[4]
                non_unique = parts[1] == '1'
                if idx_name not in indexes:
                    indexes[idx_name] = {
                        'name': idx_name,
                        'columns': [],
                        'unique': not non_unique,
                        'primary': idx_name == 'PRIMARY'
                    }
                indexes[idx_name]['columns'].append(col_name)
        
        table_info['indexes'] = list(indexes.values())
        schema['tables'].append(table_info)
    
    return schema


def extract_sqlite_schema(params, table_filter=None):
    """Extract schema from SQLite database."""
    db_name = os.path.basename(params['database'])
    schema = {
        'database': db_name,
        'type': 'sqlite',
        'extracted_at': datetime.now().isoformat(),
        'tables': []
    }
    
    # Get all tables
    tables_result = run_sqlite_query(params, "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;")
    table_names = [t.strip() for t in tables_result.split('\n') if t.strip()]
    
    if table_filter:
        table_names = [t for t in table_names if t == table_filter]
    
    for table_name in table_names:
        table_info = {'name': table_name, 'columns': [], 'primary_key': [], 'foreign_keys': [], 'indexes': []}
        
        # Get columns using PRAGMA
        columns_result = run_sqlite_query(params, f"PRAGMA table_info({table_name});")
        for line in columns_result.split('\n'):
            if not line.strip():
                continue
            parts = line.split('\t')
            if len(parts) >= 6:
                # cid, name, type, notnull, dflt_value, pk
                col_name = parts[1]
                col_type = parts[2] or 'TEXT'
                nullable = parts[3] == '0'
                default = parts[4] if parts[4] else None
                is_pk = parts[5] == '1'
                
                table_info['columns'].append({
                    'name': col_name,
                    'type': col_type,
                    'nullable': nullable,
                    'default': default,
                    'comment': None
                })
                
                if is_pk:
                    table_info['primary_key'].append(col_name)
        
        # Get foreign keys using PRAGMA
        fk_result = run_sqlite_query(params, f"PRAGMA foreign_key_list({table_name});")
        for line in fk_result.split('\n'):
            if not line.strip():
                continue
            parts = line.split('\t')
            if len(parts) >= 5:
                # id, seq, table, from, to
                table_info['foreign_keys'].append({
                    'column': parts[3],
                    'references_table': parts[2],
                    'references_column': parts[4],
                    'constraint_name': f"fk_{table_name}_{parts[3]}"
                })
        
        # Get indexes using PRAGMA
        idx_result = run_sqlite_query(params, f"PRAGMA index_list({table_name});")
        for line in idx_result.split('\n'):
            if not line.strip():
                continue
            parts = line.split('\t')
            if len(parts) >= 3:
                # seq, name, unique
                idx_name = parts[1]
                is_unique = parts[2] == '1'
                
                # Get index columns
                idx_info_result = run_sqlite_query(params, f"PRAGMA index_info({idx_name});")
                columns = []
                for idx_line in idx_info_result.split('\n'):
                    if idx_line.strip():
                        idx_parts = idx_line.split('\t')
                        if len(idx_parts) >= 3:
                            columns.append(idx_parts[2])
                
                if columns:
                    table_info['indexes'].append({
                        'name': idx_name,
                        'columns': columns,
                        'unique': is_unique,
                        'primary': idx_name.startswith('sqlite_autoindex')
                    })
        
        schema['tables'].append(table_info)
    
    return schema


def simplify_type(col_type):
    """Simplify column type for Mermaid ERD."""
    col_type = col_type.lower()
    if 'int' in col_type:
        return 'int'
    elif 'varchar' in col_type or 'text' in col_type or 'char' in col_type:
        return 'string'
    elif 'timestamp' in col_type or 'datetime' in col_type:
        return 'timestamp'
    elif 'date' in col_type:
        return 'date'
    elif 'bool' in col_type:
        return 'bool'
    elif 'decimal' in col_type or 'numeric' in col_type or 'float' in col_type or 'double' in col_type:
        return 'decimal'
    elif 'json' in col_type:
        return 'json'
    elif 'uuid' in col_type:
        return 'uuid'
    else:
        return col_type.split('(')[0]


def generate_mermaid_erd(schema):
    """Generate Mermaid ERD diagram from schema."""
    lines = ['erDiagram']
    
    # Define entities
    for table in schema['tables']:
        table_name_upper = table['name'].upper().replace('-', '_')
        lines.append(f'    {table_name_upper} {{')
        
        for col in table['columns']:
            simple_type = simplify_type(col['type'])
            constraints = []
            if col['name'] in table['primary_key']:
                constraints.append('PK')
            
            # Check if it's a foreign key
            for fk in table['foreign_keys']:
                if fk['column'] == col['name']:
                    constraints.append('FK')
                    break
            
            # Check for unique constraints
            for idx in table.get('indexes', []):
                if idx['unique'] and not idx['primary'] and col['name'] in idx['columns'] and len(idx['columns']) == 1:
                    constraints.append('UK')
                    break
            
            constraint_str = ' ' + ','.join(constraints) if constraints else ''
            col_name = col['name'].replace('-', '_')
            lines.append(f'        {simple_type} {col_name}{constraint_str}')
        
        lines.append('    }')
    
    # Define relationships
    lines.append('')
    for table in schema['tables']:
        table_name_upper = table['name'].upper().replace('-', '_')
        for fk in table['foreign_keys']:
            ref_table_upper = fk['references_table'].upper().replace('-', '_')
            # Determine relationship label
            label = fk['column'].replace('_id', '').replace('_', ' ')
            lines.append(f'    {ref_table_upper} ||--o{{ {table_name_upper} : "{label}"')
    
    return '\n'.join(lines)


def generate_markdown(schema):
    """Generate Markdown documentation from schema."""
    lines = []
    
    # Header
    lines.append(f'# Database Schema: {schema["database"]}')
    lines.append('')
    lines.append(f'**Database Type:** {schema["type"].upper()}')
    lines.append(f'**Extracted:** {schema["extracted_at"]}')
    lines.append(f'**Tables:** {len(schema["tables"])}')
    lines.append('')
    
    # Table of Contents
    lines.append('## Table of Contents')
    lines.append('')
    for table in schema['tables']:
        lines.append(f'- [{table["name"]}](#{table["name"].lower().replace("_", "-")})')
    lines.append('')
    
    # ERD Diagram
    lines.append('## Entity Relationship Diagram')
    lines.append('')
    lines.append('```mermaid')
    lines.append(generate_mermaid_erd(schema))
    lines.append('```')
    lines.append('')
    
    # Relationship Summary
    all_fks = []
    for table in schema['tables']:
        for fk in table['foreign_keys']:
            all_fks.append({
                'from_table': table['name'],
                'from_column': fk['column'],
                'to_table': fk['references_table'],
                'to_column': fk['references_column']
            })
    
    if all_fks:
        lines.append('## Relationships')
        lines.append('')
        lines.append('| From Table | Column | To Table | Referenced Column |')
        lines.append('|------------|--------|----------|-------------------|')
        for fk in all_fks:
            lines.append(f'| {fk["from_table"]} | {fk["from_column"]} | {fk["to_table"]} | {fk["to_column"]} |')
        lines.append('')
    
    # Table Details
    lines.append('## Tables')
    lines.append('')
    
    for table in schema['tables']:
        lines.append(f'### {table["name"]}')
        lines.append('')
        
        # Infer table purpose from name and relationships
        purpose = infer_table_purpose(table)
        if purpose:
            lines.append(f'**Purpose:** {purpose}')
            lines.append('')
        
        # Columns table
        lines.append('| Column | Type | Nullable | Default | Constraints |')
        lines.append('|--------|------|----------|---------|-------------|')
        
        for col in table['columns']:
            constraints = []
            if col['name'] in table['primary_key']:
                constraints.append('PK')
            for fk in table['foreign_keys']:
                if fk['column'] == col['name']:
                    constraints.append(f'FK -> {fk["references_table"]}')
            for idx in table.get('indexes', []):
                if idx['unique'] and not idx['primary'] and col['name'] in idx['columns']:
                    constraints.append('UNIQUE')
            
            nullable = 'Yes' if col['nullable'] else 'No'
            default = col['default'] or '-'
            constraint_str = ', '.join(constraints) if constraints else '-'
            
            lines.append(f'| {col["name"]} | {col["type"]} | {nullable} | {default} | {constraint_str} |')
        
        lines.append('')
        
        # Indexes
        non_pk_indexes = [idx for idx in table.get('indexes', []) if not idx['primary']]
        if non_pk_indexes:
            lines.append('**Indexes:**')
            for idx in non_pk_indexes:
                unique_str = ' (unique)' if idx['unique'] else ''
                lines.append(f'- `{idx["name"]}`: {", ".join(idx["columns"])}{unique_str}')
            lines.append('')
    
    return '\n'.join(lines)


def infer_table_purpose(table):
    """Infer table purpose from its name and structure."""
    name = table['name'].lower()
    
    # Common patterns
    if name in ('users', 'user', 'accounts', 'account'):
        return 'Stores user account information'
    elif name in ('orders', 'order'):
        return 'Stores order/purchase records'
    elif 'order_item' in name or 'orderitem' in name or 'line_item' in name:
        return 'Stores individual items within orders'
    elif name in ('products', 'product', 'items', 'item'):
        return 'Stores product/item catalog'
    elif name in ('categories', 'category'):
        return 'Stores category hierarchies'
    elif 'session' in name:
        return 'Stores user session data'
    elif 'log' in name or 'audit' in name:
        return 'Audit/logging table for tracking changes'
    elif 'config' in name or 'setting' in name:
        return 'Stores configuration/settings'
    elif name.endswith('_history') or name.endswith('_log'):
        base = name.rsplit('_', 1)[0]
        return f'Historical records for {base}'
    
    # Check if it's a junction/pivot table (many-to-many)
    fk_count = len(table['foreign_keys'])
    col_count = len(table['columns'])
    if fk_count >= 2 and col_count <= fk_count + 3:
        tables = [fk['references_table'] for fk in table['foreign_keys']]
        return f'Junction table linking {" and ".join(tables)}'
    
    return None


def main():
    parser = argparse.ArgumentParser(description='Extract database schema')
    parser.add_argument('--output', choices=['json', 'markdown'], default='json', help='Output format')
    parser.add_argument('--table', help='Extract specific table only')
    parser.add_argument('--file', help='Save output to file')
    parser.add_argument('--type', choices=['postgres', 'mysql', 'sqlite'], help='Database type')
    parser.add_argument('--database', help='Database path (for SQLite) or name')
    
    args = parser.parse_args()
    
    db_type = args.type or detect_database_type()
    
    if not db_type:
        print("Error: Could not detect database type. Please set environment variables or specify --type", file=sys.stderr)
        sys.exit(1)
    
    params = get_connection_params(db_type, args)
    
    # Validate required params
    if db_type == 'sqlite':
        if not params.get('database'):
            print("Error: Missing database path for SQLite", file=sys.stderr)
            sys.exit(1)
        if not os.path.exists(params['database']):
            print(f"Error: Database file not found: {params['database']}", file=sys.stderr)
            sys.exit(1)
    else:
        missing = [k for k, v in params.items() if not v and k != 'password']
        if missing:
            print(f"Error: Missing required parameters: {', '.join(missing)}", file=sys.stderr)
            sys.exit(1)
    
    try:
        if db_type == 'postgres':
            schema = extract_postgres_schema(params, args.table)
        elif db_type == 'mysql':
            schema = extract_mysql_schema(params, args.table)
        else:
            schema = extract_sqlite_schema(params, args.table)
        
        if args.output == 'json':
            output = json.dumps(schema, indent=2)
        else:
            output = generate_markdown(schema)
        
        if args.file:
            # Ensure directory exists
            os.makedirs(os.path.dirname(args.file) or '.', exist_ok=True)
            with open(args.file, 'w') as f:
                f.write(output)
            print(f"Schema saved to {args.file}")
        else:
            print(output)
            
    except Exception as e:
        print(f"Error extracting schema: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
