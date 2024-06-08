# doris-iceberg-paimon-compose


## Launch Docker Compose
First, we need to ensure the environmental parameters of the machine.

```
sysctl -w vm.max_map_count=2000000
```

We can then start all the required containers via the script.

```
bash start_all.sh
```
It will start a set of docker, the environment includes:
- doris
- iceberg
- paimon
- flink
- spark

And it will automatically create an iceberg table and a paimon table. We can use these tables directly to experience doris.


## paimon table test

Enter the flink client.

```
bash start_flink_client.sh
```

Here is a table that has been created.

```sql

Flink SQL> use paimon.db_paimon;
[INFO] Execute statement succeed.

Flink SQL> show tables;
+------------+
| table name |
+------------+
|  tb_paimon |
+------------+
1 row in set

Flink SQL> show create table tb_paimon;
+------------------------------------------------------------------------+
|                                                                 result |
+------------------------------------------------------------------------+
| CREATE TABLE `paimon`.`db_paimon`.`tb_paimon` (
  `id` BIGINT NOT NULL,
  `val` VARCHAR(2147483647),
  CONSTRAINT `PK_id` PRIMARY KEY (`id`) NOT ENFORCED
) WITH (
  'path' = 's3://warehouse/wh/db_paimon.db/tb_paimon',
  'deletion-vectors.enabled' = 'true'
)
 |
+-------------------------------------------------------------------------+
1 row in set

Flink SQL> desc tb_paimon;
+------+--------+-------+---------+--------+-----------+
| name |   type |  null |     key | extras | watermark |
+------+--------+-------+---------+--------+-----------+
|   id | BIGINT | FALSE | PRI(id) |        |           |
|  val | STRING |  TRUE |         |        |           |
+------+--------+-------+---------+--------+-----------+
2 rows in set
```

Insert some data into the table and query the data directly.

```sql
Flink SQL> insert into tb_paimon values (1,'a'),(2,'a'),(3,'a');
[INFO] Submitting SQL update statement to the cluster...
[INFO] SQL update statement has been successfully submitted to the cluster:
Job ID: 8feab6d2e05634081146df6870cbacb5

Flink SQL> select * from tb_paimon order by id;
2024-06-08 05:51:49,331 INFO  org.apache.hadoop.fs.s3a.S3AInputStream                      [] - Switching to Random IO seek policy
2024-06-08 05:51:49,369 INFO  org.apache.hadoop.fs.s3a.S3AInputStream                      [] - Switching to Random IO seek policy
2024-06-08 05:51:49,399 INFO  org.apache.hadoop.fs.s3a.S3AInputStream                      [] - Switching to Random IO seek policy

+----+-----+
| id | val |
+----+-----+
|  1 |   a |
|  2 |   a |
|  3 |   a |
+----+-----+
3 rows in set
```

Now we can query this table through doris.

```
bash start_doris_client.sh
```

After entering the doris client, the paimon catalog has been created here, so the data of the paimon table can be directly queried.

```sql
mysql> use paimon.db_paimon;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> show tables;
+---------------------+
| Tables_in_db_paimon |
+---------------------+
| tb_paimon           |
+---------------------+
1 row in set (0.00 sec)

-- Use jni reader to query table data
mysql> set force_jni_scanner = true;
Query OK, 0 rows affected (0.02 sec)

mysql> select * from tb_paimon order by id;
+------+------+
| id   | val  |
+------+------+
|    1 | a    |
|    2 | a    |
|    3 | a    |
+------+------+
3 rows in set (1.91 sec)

-- Use native reader to query table data
mysql> set force_jni_scanner = false;
Query OK, 0 rows affected (0.01 sec)

mysql> select * from tb_paimon order by id;
+------+------+
| id   | val  |
+------+------+
|    1 | a    |
|    2 | a    |
|    3 | a    |
+------+------+
3 rows in set (0.22 sec)
```

Next, modify the data in the paimon table by flink.

```sql
Flink SQL> insert into tb_paimon values (2,'b'), (4,'a');
[INFO] Submitting SQL update statement to the cluster...
[INFO] SQL update statement has been successfully submitted to the cluster:
Job ID: 1d4c933cd36975c36e39232065d81f22


Flink SQL> select * from tb_paimon order by id;
2024-06-08 06:52:54,328 INFO  org.apache.hadoop.fs.s3a.S3AInputStream                      [] - Switching to Random IO seek policy
2024-06-08 06:52:54,337 INFO  org.apache.hadoop.fs.s3a.S3AInputStream                      [] - Switching to Random IO seek policy
2024-06-08 06:52:54,350 INFO  org.apache.hadoop.fs.s3a.S3AInputStream                      [] - Switching to Random IO seek policy
2024-06-08 06:52:54,350 INFO  org.apache.hadoop.fs.s3a.S3AInputStream                      [] - Switching to Random IO seek policy
2024-06-08 06:52:54,350 INFO  org.apache.hadoop.fs.s3a.S3AInputStream                      [] - Switching to Random IO seek policy
2024-06-08 06:52:54,350 INFO  org.apache.hadoop.fs.s3a.S3AInputStream                      [] - Switching to Random IO seek policy
2024-06-08 06:52:54,386 INFO  org.apache.hadoop.fs.s3a.S3AInputStream                      [] - Switching to Random IO seek policy

+----+-----+
| id | val |
+----+-----+
|  1 |   a |
|  2 |   b |
|  3 |   a |
|  4 |   a |
+----+-----+
4 rows in set
```

Similarly, you can query the updated data in doris.

```sql
mysql> refresh table tb_paimon;
Query OK, 0 rows affected (0.02 sec)

-- Use jni reader to query table data
mysql> set force_jni_scanner = true;
Query OK, 0 rows affected (0.00 sec)

mysql> select * from tb_paimon order by id;
+------+------+
| id   | val  |
+------+------+
|    1 | a    |
|    2 | b    |
|    3 | a    |
|    4 | a    |
+------+------+
4 rows in set (0.42 sec)

-- Use native reader to query table data
mysql> set force_jni_scanner = false;
Query OK, 0 rows affected (0.01 sec)

mysql> select * from tb_paimon order by id;
+------+------+
| id   | val  |
+------+------+
|    1 | a    |
|    2 | b    |
|    3 | a    |
|    4 | a    |
+------+------+
4 rows in set (0.25 sec)
```
