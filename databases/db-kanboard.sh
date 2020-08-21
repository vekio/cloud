#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE kanboard;
    CREATE USER kanboard with encrypted password 'kanboard';
    GRANT ALL PRIVILEGES ON DATABASE kanboard TO kanboard;
EOSQL