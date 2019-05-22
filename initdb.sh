#!/bin/bash
set -e
echo "Creating user and database"
psql -p 5432 -U postgres <<-EOSQL
    CREATE USER microaccounts_dev WITH PASSWORD 'r783qjkldDsiu';
    CREATE DATABASE elixir_beacon_dev;
    CREATE DATABASE elixir_beacon_testing;
    GRANT ALL PRIVILEGES ON DATABASE elixir_beacon_dev TO microaccounts_dev;
    GRANT ALL PRIVILEGES ON DATABASE elixir_beacon_testing TO microaccounts_dev;
EOSQL

echo "Creating DB schema"
PGPASSWORD=r783qjkldDsiu \
    psql -p 5432 -U microaccounts_dev -d elixir_beacon_dev < /tmp/elixir_beacon_db_schema.sql
    psql -p 5432 -U microaccounts_dev -d elixir_beacon_testing < /tmp/elixir_beacon_db_schema.sql

