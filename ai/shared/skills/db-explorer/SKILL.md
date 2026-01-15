---
name: db-explorer
description: Connect to PostgreSQL, MySQL, or SQLite databases to explore schema structure, table relationships, and generate ERD diagrams. Use when the user asks to explore a database, document schema, or understand table relationships.
---

# Database Explorer

Analyze database schema and generate Markdown documentation with Mermaid ERD diagrams.

## Workflow

1. **Check credentials:** Run `scripts/db_connect.py --check-env`
2. **If credentials missing:** Ask the user for:
   - Database type (postgres/mysql/sqlite)
   - For SQLite: path to the .db file
   - For PostgreSQL/MySQL: host, port, database name, username, password
3. **Test connection:** `scripts/db_connect.py --test --type <type> --host <host> --database <db> --user <user> --password <pass>`
4. **Extract schema:** `scripts/schema_extractor.py --output markdown --file .tmp/docs/db-schema-{dbname}.md`

## Environment Variables (optional)

Users can pre-set credentials to skip prompts:

- **PostgreSQL:** `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`
- **MySQL:** `MYSQL_HOST`, `MYSQL_TCP_PORT`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PWD`
- **SQLite:** `SQLITE_DATABASE`
- **Alternative:** `DATABASE_URL` (e.g., `postgresql://user:pass@host:5432/dbname`)

## Mermaid ERD Notation

- `||--||` One-to-one
- `||--o{` One-to-many  
- `||--|{` One-to-many (required)

## Security

- Never log or echo passwords in output
- Query system tables only, never user data
