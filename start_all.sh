set -e

DORIS_PACKAGE=doris-hudi-2.1
DORIS_DOWNLOAD_URL=justtmp-bj-1308700295.cos.ap-beijing.myqcloud.com/gaoxin

md5_jdk8="0029351f7a946f6c05b582100c7d45b7"
md5_doris="7991e1fa85a68d6243ebcce984cd43a7"

download_source_file() {
  local FILE_PATH="$1"
  local EXPECTED_MD5="$2"
  local DOWNLOAD_URL="$3"

  echo "Download $FILE_PATH"

  if [ -f "$FILE_PATH" ]; then
    local FILE_MD5
    FILE_MD5=$(md5sum "$FILE_PATH" | awk '{ print $1 }')

    if [ "$FILE_MD5" = "$EXPECTED_MD5" ]; then
      echo "$FILE_PATH is ready!"
    else
      echo "$FILE_PATH is broken, Redownloading ..."
      rm $FILE_PATH
      wget ${DOWNLOAD_URL}/${FILE_PATH}
    fi
  else
    echo "Downloading $FILE_PATH ..."
    wget ${DOWNLOAD_URL}/${FILE_PATH}
  fi
}


curdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
cd ${curdir}

if [ ! -d "packages" ]; then
  mkdir packages
fi
cd packages

download_source_file "jdk-8u202-linux-x64.tar.gz" "$md5_jdk8" "https://repo.huaweicloud.com/java/jdk/8u202-b08"
download_source_file "${DORIS_PACKAGE}.tar.gz" "$md5_doris" "$DORIS_DOWNLOAD_URL"

if [ ! -f "jdk1.8.0_202/SUCCESS" ]; then
  echo "Prepare jdk8 environment"
  if [ -d "jdk1.8.0_202" ]; then
    echo "Remove broken jdk1.8.0_202"
    rm -rf jdk1.8.0_202
  fi
  echo "Unpackage jdk1.8.0_202"
  tar xzf jdk-8u202-linux-x64.tar.gz
  touch jdk1.8.0_202/SUCCESS
fi

if [ ! -f "doris-bin/SUCCESS" ]; then
  echo "Prepare $DORIS_PACKAGE environment"
  if [ -d "doris-bin" ]; then
    echo "Remove broken $DORIS_PACKAGE"
    rm -rf doris-bin
  fi
  echo "Unpackage $DORIS_PACKAGE"
  tar xzf ${DORIS_PACKAGE}.tar.gz
  mv ${DORIS_PACKAGE} doris-bin
  touch doris-bin/SUCCESS
fi

cd ../
echo $PWD

echo "Start docker-compose..."
docker compose -f docker-compose.yml --env-file docker-compose.env up -d

echo "Start init iceberg and paimon tables..."
docker exec -it doris-iceberg-paimon-jobmanager sql-client.sh -f /opt/flink/sql/init_tables.sql >> init.log

echo "Start prepare data for tables..."
docker exec -it doris-iceberg-paimon-spark spark-sql --conf spark.sql.extensions=org.apache.paimon.spark.extensions.PaimonSparkSessionExtensions -f /opt/sql/prepare_data.sql >> init.log

echo "============================================================================="
echo "Success to launch doris+iceberg+paimon+flink+spark+minio environments!"
echo "You can:"
echo "    'bash start_doris.sh' to login into doris"
echo "    'bash start_flink_client.sh' to login into flink"
echo "    'bash start_spark_paimon_client.sh' to login into spark for paimon"
echo "    'bash start_spark_iceberg_client.sh' to login into spark for iceberg"
echo "============================================================================="
