#!/bin/bash
set -e


echo "load dataset information into database"
PGPASSWORD=r783qjkldDsiu \
    psql -U microaccounts_dev elixir_beacon_dev <<-EOSQL
        INSERT INTO beacon_dataset_table (id, stable_id, description, access_type, reference_genome, variant_cnt, call_cnt, sample_cnt) 
            VALUES (1, '1000genomes', 'Subset of variants of chromosomes 22 and Y from the 1000 genomes project', 'PUBLIC', 'GRCh37', 3119, 8513330, 2504);
        INSERT INTO beacon_dataset_consent_code_table (dataset_id, consent_code_id , additional_constraint, version) 
            VALUES(1, 1, null, 'v1.0');
EOSQL



echo "Load the variants..."
    cat 1_chrY_subset.variants.csv | \
        PGAPASSWORD=r783qjkldDsiu \
        psql -U microaccounts_dev elixir_beacon_dev -c \
        "COPY beacon_data_table (dataset_id,chromosome,start,variant_id,reference,alternate,\"end\","type",sv_length,variant_cnt,call_cnt,sample_cnt, frequency,matching_sample_cnt) FROM STDIN USING DELIMITERS ';' CSV HEADER"
    
    cat 1_chr21_subset.variants.csv | \
        PGAPASSWORD=r783qjkldDsiu \
        psql -U microaccounts_dev elixir_beacon_dev -c \
        "COPY beacon_data_table (dataset_id,chromosome,start,variant_id,reference,alternate,\"end\","type",sv_length,variant_cnt,call_cnt,sample_cnt, frequency,matching_sample_cnt) FROM STDIN USING DELIMITERS ';' CSV HEADER"

    
    cat sg10k_chr1.after_QC.phased.AF_updated.variants.csv | \
        PGAPASSWORD=r783qjkldDsiu \
        psql -U microaccounts_dev elixir_beacon_dev -c \
        "COPY beacon_data_table (dataset_id,chromosome,start,variant_id,reference,alternate,\"end\","type",sv_length,variant_cnt,call_cnt,sample_cnt, frequency,matching_sample_cnt) FROM STDIN USING DELIMITERS ';' CSV HEADER"
    
    
    
echo "done."


echo "Load the samples..."
    cat 1_chrY_subset.samples.csv | \
        PGAPASSWORD=r783qjkldDsiu \
        psql -U microaccounts_dev elixir_beacon_dev -c \
        "COPY tmp_sample_table (sample_stable_id,dataset_id) FROM STDIN USING DELIMITERS ';' CSV HEADER"
    
    cat 1_chr21_subset.samples.csv | \
        PGAPASSWORD=r783qjkldDsiu \
        psql -U microaccounts_dev elixir_beacon_dev -c \
        "COPY tmp_sample_table (sample_stable_id,dataset_id) FROM STDIN USING DELIMITERS ';' CSV HEADER"

    
    cat sg10k_chr1.after_QC.phased.AF_updated.samples.csv | \
        PGAPASSWORD=r783qjkldDsiu \
        psql -U microaccounts_dev elixir_beacon_dev -c \
        "COPY tmp_sample_table (sample_stable_id,dataset_id) FROM STDIN USING DELIMITERS ';' CSV HEADER"
echo "done."


echo "Fill final table beacon_sample_tabe"
PGAPASSWORD=r783qkldDsiu \
    psql -U microaccounts_dev elixir_beacon_dev <<-EOSQL
        INSERT INTO beacon_sample_table (stable_id)
        SELECT DISTINCT t.sample_stable_id
        FROM tmp_sample_table t
        LEFT JOIN beacon_sample_table sam ON sam.stable_id=t.sample_stable_id
        WHERE sam.id IS NULL;
EOSQL
echo "done"


echo "fill linking table beacon_dataset_sample_table"
PGAPASSWORD=r783qkldDsiu \
    psql -U microaccounts_dev elixir_beacon_dev <<-EOSQL
        INSERT INTO beacon_dataset_sample_table (dataset_id, sample_id)
        SELECT DISTINCT dat.id AS dataset_id, sam.id AS sample_id
        FROM tmp_sample_table t
        INNER JOIN beacon_sample_table sam ON sam.stable_id=t.sample_stable_id
        INNER JOIN beacon_dataset_table dat ON dat.id=t.dataset_id
        LEFT JOIN beacon_dataset_sample_table dat_sam ON dat_sam.dataset_id=dat.id AND dat_sam.sample_id=sam.id
        WHERE dat_sam.id IS NULL;
EOSQL
echo "done"




echo "load 'variants matching samples' table..."
cat 1_chrY_subset.variants.matching.samples.csv | \
    PGPASSWORD=r783qjkldDsiu \
    psql -U microaccounts_dev elixir_beacon_dev -c \
"COPY tmp_data_sample_table (dataset_id,chromosome,start,variant_id,reference,alternate,"type",sample_ids) FROM STDIN USING DELIMITERS ';' CSV HEADER"

cat 1_chr21_subset.variants.matching.samples.csv | \
    PGPASSWORD=r783qjkldDsiu \
    psql -U microaccounts_dev elixir_beacon_dev -c \
"COPY tmp_data_sample_table (dataset_id,chromosome,start,variant_id,reference,alternate,"type",sample_ids) FROM STDIN USING DELIMITERS ';' CSV HEADER"


cat sg10k_chr1.after_QC.phased.AF_updated.variants.matching.samples.csv | \
    PGPASSWORD=r783qjkldDsiu \
    psql -U microaccounts_dev elixir_beacon_dev -c \
"COPY tmp_data_sample_table (dataset_id,chromosome,start,variant_id,reference,alternate,"type",sample_ids) FROM STDIN USING DELIMITERS ';' CSV HEADER"
echo "done."





echo "fill final linking table"
PGAPASSWORD=r783qkldDsiu \
    psql -U microaccounts_dev elixir_beacon_dev <<-EOSQL
        INSERT INTO beacon_data_sample_table (data_id, sample_id)
        select data_sam_unnested.data_id, s.id AS sample_id
        from (
            select dt.id as data_id, unnest(t.sample_ids) AS sample_stable_id
            from tmp_data_sample_table t
            inner join beacon_data_table dt ON dt.dataset_id=t.dataset_id and dt.chromosome=t.chromosome
                and dt.variant_id=t.variant_id and dt.reference=t.reference and dt.alternate=t.alternate
                and dt.start=t.start and dt.type=t.type 
        )data_sam_unnested
        inner join beacon_sample_table s on s.stable_id=data_sam_unnested.sample_stable_id
        left join beacon_data_sample_table ds ON ds.data_id=data_sam_unnested.data_id and ds.sample_id=s.id
        where ds.data_id is null;
EOSQL
echo "done."


PGPASSWORD=r783qkldDsiu \
    psql -U microaccounts_dev elixir_beacon_dev <<-EOSQL
        TRUNCATE TABLE tmp_sample_table;
        TRUNCATE TABLE tmp_data_sample_table;
EOSQL


PGPASSWORD=r783qkldDsiu \
    psql -U microaccounts_dev elixir_beacon_dev <<-EOSQL
        UPDATE beacon_dataset_table SET variant_cnt =
        (SELECT count(*) FROM beacon_data_table);
EOSQL


PGPASSWORD=r783qkldDsiu \
    psql -U microaccounts_dev elixir_beacon_dev <<-EOSQL
        UPDATE beacon_dataset_table SET call_cnt =
        (SELECT sum(call_cnt) FROM beacon_data_table);
EOSQL


PGPASSWORD=r783qkldDsiu \
    psql -U microaccounts_dev elixir_beacon_dev <<-EOSQL
        UPDATE beacon_dataset_table SET sample_cnt = 
        (SELECT COUNT(sample_id) FROM beacon_dataset_table dat 
        INNER JOIN beacon_dataset_sample_table dat_sam ON dat_sam.dataset_id=dat.id 
        GROUP BY dat.id);
EOSQL


echo "create functions"
PGAPASSWORD=r783qjkldDsiu psql -h localhost -p 5432 -d elixir_beacon_dev -U microaccounts_dev < /tmp/elixir_beacon_function_summary_response.sql  
PGAPASSWORD=r783qjkldDsiu psql -h localhost -p 5432 -d elixir_beacon_testing -U microaccounts_dev < /tmp/elixir_beacon_function_summary_response.sql  
echo "done"

