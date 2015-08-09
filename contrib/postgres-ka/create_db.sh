#!/bin/bash

gosu postgres psql --user postgres <<-EOSQL
	CREATE DATABASE nomenklatura;
  GRANT ALL PRIVILEGES ON DATABASE nomenklatura TO kleineanfragen;
EOSQL