#!/bin/bash -x 

[ -n "${ES_URL}" ] || { echo "Please set ES_URL env var"; exit 1; }
[ -n "${ES_INDEX_PATTERN}" ] || { echo "Please set ES_INDEX_PATTERN env var"; exit 1; }
[ -n "${CSV_TMPFILE_PATH}" ] || { echo "Please set CSV_TMPFILE_PATH env var"; exit 1; }
[ -n "${PG_HOST}" ] || { echo "Please set PG_HOST env var"; exit 1; }
[ -n "${PG_DATABASE}" ] || { echo "Please set PG_DATABASE env var"; exit 1; }
[ -n "${PG_USER}" ] || { echo "Please set PG_USER env var"; exit 1; }
[ -n "${PG_PASSWORD}" ] || { echo "Please set PG_PASSWORD env var"; exit 1; }
[ -n "${PG_SCHEMA_FILE}" ] || { echo "Please set PG_SCHEMA_FILE env var"; exit 1; }
[ -n "${PG_TABLE_NAME}" ] || { echo "Please set PG_TABLE_NAME env var"; exit 1; }
[ -n "${PG_SCHEMA_NAME}" ] || { echo "Please set PG_SCHEMA_NAME env var"; exit 1; }
[ -n "${PG_TIME_FIELD}" ] || { echo "Please set PG_TIME_FIELD env var"; exit 1; }
[ -n "${REFRESH_INTERVAL}" ] || { echo "Please set REFRESH_INTERVAL env var"; exit 1; }
[ -n "${CSV_SED_CMD}" ] || { echo "No CSV_SED_CMD is specified"; }

set -eEuo pipefail

FILTERED_CSV_PATH=${CSV_TMPFILE_PATH}.filtered

export PGHOST=${PG_HOST}
export PGDATABASE=${PG_DATABASE}
export PGUSER=${PG_USER}
export PGPASSWORD=${PG_PASSWORD}


## Init
table_exists=$(psql -X -A -t -c "SELECT EXISTS (SELECT 1 FROM  information_schema.tables WHERE table_schema = '${PG_SCHEMA_NAME}' AND table_name = '${PG_TABLE_NAME}')")
#if [ "${table_exists}" != "t" ]; then
  psql -f ${PG_SCHEMA_FILE}
#fi

table_column_names=$(psql -X -A -t -c "select column_name FROM information_schema.columns WHERE table_schema='${PG_SCHEMA_NAME}' AND table_name='${PG_TABLE_NAME}'")


## Main
while true; do
  last_timestamp=$(psql -X -A -t -c "SELECT ${PG_TIME_FIELD} from ${PG_TABLE_NAME} ORDER BY ${PG_TIME_FIELD} DESC LIMIT 1")
  if [ -z "${last_timestamp}" ]; then
    start_date="2020-02-06"
  else
    start_date=${last_timestamp}  
  fi

  es2csv --url ${ES_URL} \
         --scroll-size 1000 \
         --raw \
         --query "{\"query\": {\"range\": {\"@timestamp\": {\"gt\": \"${start_date}\", \"lte\": \"now\"}}}}" \
         --index-prefixes "${ES_INDEX_PATTERN}" \
         --meta-fields \
         --kibana-nested \
         --output ${CSV_TMPFILE_PATH}

  if [ ! -z "${CSV_SED_CMD}" ]; then
    sed -i "${CSV_SED_CMD}" ${CSV_TMPFILE_PATH} 
  fi


  # xsv fails if we specify columns which does not exists.
  existent_column_names=""
  for column_name in ${table_column_names}; do
    head -1 ${CSV_TMPFILE_PATH} | grep ${column_name} && existent_column_names="${existent_column_names}${column_name},"
  done
  cat ${CSV_TMPFILE_PATH} | xsv select ${existent_column_names::-1} > ${FILTERED_CSV_PATH}

  psql -c "\\copy ${PG_TABLE_NAME}($(head -1 ${FILTERED_CSV_PATH})) FROM ${FILTERED_CSV_PATH} CSV HEADER"

  rm -f ${CSV_TMPFILE_PATH} ${FILTERED_CSV_PATH}

  sleep ${REFRESH_INTERVAL}
done
