docker exec -it doris-iceberg-paimon-spark spark-sql --conf spark.sql.extensions=org.apache.paimon.spark.extensions.PaimonSparkSessionExtensions