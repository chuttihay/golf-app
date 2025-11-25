#!/bin/sh

set -e

echo " Running database initialization..."

python init_db.py

echo "Database initialization script finished."

exec "$@"