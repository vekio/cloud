#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE freshrss;
    CREATE USER freshrss with encrypted password 'freshrss';
    GRANT ALL PRIVILEGES ON DATABASE freshrss TO freshrss;
EOSQL