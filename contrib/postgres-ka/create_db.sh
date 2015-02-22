#!/bin/bash

gosu postgres postgres --single -jE <<-EOSQL
	CREATE DATABASE nomenklatura;
EOSQL

gosu postgres postgres --single -jE <<-EOSQL
    GRANT ALL PRIVILEGES ON DATABASE nomenklatura TO kleineanfragen;
EOSQL

gosu postgres postgres --single -jE nomenklatura <<-EOSQL
	CREATE EXTENSION hstore;
	CREATE EXTENSION fuzzystrmatch;
EOSQL
