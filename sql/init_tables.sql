SET 'sql-client.execution.result-mode' = 'tableau';
SET 'execution.runtime-mode' = 'batch';


CREATE CATALOG iceberg WITH (
  'type'='iceberg',
  'catalog-type'='rest',
  'uri'='http://rest:8181/',
  's3.endpoint'='http://minio:9000',
  'warehouse'='s3://warehouse/wh/'
);

create database if not exists iceberg.db_iceberg;


CREATE TABLE if not exists iceberg.db_iceberg.tb_iceberg (
    id BIGINT,
    val string,
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
'write.upsert.enabled'='true',
'upsert-enabled'='true',
'write.delete.mode'='merge-on-read',
'write.update.mode'='merge-on-read'
);


CREATE CATALOG `paimon` WITH (
    'type' = 'paimon',
    'warehouse' = 's3://warehouse/wh',
    's3.endpoint'='http://minio:9000',
    's3.access-key' = 'admin',
    's3.secret-key' = 'password',
    's3.region' = 'us-east-1'
);


create database if not exists paimon.db_paimon;

CREATE TABLE if not exists paimon.db_paimon.tb_paimon (
    id BIGINT,
    val string,
    PRIMARY KEY (id) NOT ENFORCED
) with (
    'deletion-vectors.enabled' = 'true'
);

