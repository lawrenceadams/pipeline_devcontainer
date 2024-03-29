#!/bin/bash
set -e

OMOP_URL="https://athena.ohdsi.org/api/v1/vocabularies/zip/6f350fdf-7837-43e5-9ee5-a1f1dac971d9"

echo "::step::Downloading OMOP Vocab..."

mkdir /tmp/vocab/
wget $OMOP_URL -O /tmp/vocab/vocab.zip

echo "::step::Decompressing..."
unzip /tmp/vocab/vocab.zip -d /tmp/vocab/

POSTGRES="psql --username postgres -h localhost"

echo "::step::Creating database: cdm_dpp_oncology"

$POSTGRES <<EOSQL
CREATE DATABASE cdm_dpp_oncology OWNER postgres;
\connect cdm_dpp_oncology

CREATE SCHEMA omop_source;

CREATE TABLE omop_source.CONCEPT (
			concept_id integer NOT NULL,
			concept_name varchar(255) NOT NULL,
			domain_id varchar(20) NOT NULL,
			vocabulary_id varchar(20) NOT NULL,
			concept_class_id varchar(20) NOT NULL,
			standard_concept varchar(1) NULL,
			concept_code varchar(50) NOT NULL,
			valid_start_date date NOT NULL,
			valid_end_date date NOT NULL,
			invalid_reason varchar(1) NULL );

CREATE TABLE omop_source.CONCEPT_CLASS (
			concept_class_id varchar(20) NOT NULL,
			concept_class_name varchar(255) NOT NULL,
			concept_class_concept_id integer NOT NULL );

CREATE TABLE omop_source.CONCEPT_RELATIONSHIP (
			concept_id_1 integer NOT NULL,
			concept_id_2 integer NOT NULL,
			relationship_id varchar(20) NOT NULL,
			valid_start_date date NOT NULL,
			valid_end_date date NOT NULL,
			invalid_reason varchar(1) NULL );

CREATE TABLE omop_source.RELATIONSHIP (
			relationship_id varchar(20) NOT NULL,
			relationship_name varchar(255) NOT NULL,
			is_hierarchical varchar(1) NOT NULL,
			defines_ancestry varchar(1) NOT NULL,
			reverse_relationship_id varchar(20) NOT NULL,
			relationship_concept_id integer NOT NULL );

CREATE TABLE omop_source.CONCEPT_SYNONYM (
			concept_id integer NOT NULL,
			concept_synonym_name varchar(1000) NOT NULL,
			language_concept_id integer NOT NULL );

CREATE TABLE omop_source.CONCEPT_ANCESTOR (
			ancestor_concept_id integer NOT NULL,
			descendant_concept_id integer NOT NULL,
			min_levels_of_separation integer NOT NULL,
			max_levels_of_separation integer NOT NULL );

CREATE TABLE omop_source.DOMAIN (
			domain_id varchar(20) NOT NULL,
			domain_name varchar(255) NOT NULL,
			domain_concept_id integer NOT NULL );

CREATE TABLE omop_source.DRUG_STRENGTH (
			drug_concept_id integer NOT NULL,
			ingredient_concept_id integer NOT NULL,
			amount_value NUMERIC NULL,
			amount_unit_concept_id integer NULL,
			numerator_value NUMERIC NULL,
			numerator_unit_concept_id integer NULL,
			denominator_value NUMERIC NULL,
			denominator_unit_concept_id integer NULL,
			box_size integer NULL,
			valid_start_date date NOT NULL,
			valid_end_date date NOT NULL,
			invalid_reason varchar(1) NULL );

CREATE TABLE omop_source.VOCABULARY (
			vocabulary_id varchar(20) NOT NULL,
			vocabulary_name varchar(255) NOT NULL,
			vocabulary_reference varchar(255) NULL,
			vocabulary_version varchar(255) NULL,
			vocabulary_concept_id integer NOT NULL );

EOSQL

echo 
echo "::step::Hydrating OMOP Source Schema..."
echo 

psql -U postgres -d cdm_dpp_oncology -c "\copy omop_source.concept_ancestor FROM '/tmp/vocab/CONCEPT_ANCESTOR.csv' WITH DELIMITER E'\t' QUOTE E'\b' CSV HEADER" -h localhost
psql -U postgres -d cdm_dpp_oncology -c "\copy omop_source.concept_class FROM '/tmp/vocab/CONCEPT_CLASS.csv' WITH DELIMITER E'\t' QUOTE E'\b' CSV HEADER" -h localhost
psql -U postgres -d cdm_dpp_oncology -c "\copy omop_source.concept_relationship FROM '/tmp/vocab/CONCEPT_RELATIONSHIP.csv' WITH DELIMITER E'\t' QUOTE E'\b' CSV HEADER" -h localhost
psql -U postgres -d cdm_dpp_oncology -c "\copy omop_source.concept_synonym FROM '/tmp/vocab/CONCEPT_SYNONYM.csv' WITH DELIMITER E'\t' QUOTE E'\b' CSV HEADER" -h localhost
psql -U postgres -d cdm_dpp_oncology -c "\copy omop_source.concept FROM '/tmp/vocab/CONCEPT.csv' WITH DELIMITER E'\t' QUOTE E'\b' CSV HEADER" -h localhost
psql -U postgres -d cdm_dpp_oncology -c "\copy omop_source.domain FROM '/tmp/vocab/DOMAIN.csv' WITH DELIMITER E'\t' QUOTE E'\b' CSV HEADER" -h localhost
psql -U postgres -d cdm_dpp_oncology -c "\copy omop_source.drug_strength FROM '/tmp/vocab/DRUG_STRENGTH.csv' WITH DELIMITER E'\t' QUOTE E'\b' CSV HEADER" -h localhost
psql -U postgres -d cdm_dpp_oncology -c "\copy omop_source.relationship FROM '/tmp/vocab/RELATIONSHIP.csv' WITH DELIMITER E'\t' QUOTE E'\b' CSV HEADER" -h localhost
psql -U postgres -d cdm_dpp_oncology -c "\copy omop_source.vocabulary FROM '/tmp/vocab/VOCABULARY.csv' WITH DELIMITER E'\t' QUOTE E'\b' CSV HEADER" -h localhost

echo 
echo "::step::Cleanup vocab files"
rm -r /tmp/vocab

echo "::step::Done."
echo "Connect with:"
echo "    psql -U postgres -h localhost -d cdm_dpp_oncology"
