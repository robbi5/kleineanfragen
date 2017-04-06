#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
  CREATE DATABASE nomenklatura;
  GRANT ALL PRIVILEGES ON DATABASE nomenklatura TO kleineanfragen;
EOSQL