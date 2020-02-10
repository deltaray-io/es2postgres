# es2postgres

[![docker build](https://img.shields.io/docker/cloud/build/tibkiss/es2postgres.svg)](https://hub.docker.com/r/tibkiss/es2postgres)
[![docker pulls](https://img.shields.io/docker/pulls/tibkiss/es2postgres.svg)](https://hub.docker.com/r/tibkiss/es2postgres)
[![license](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

ElasticSearch to PostgreSQL Loader.
Uses es2csv, xsv, sed and psql client to periodically Extract, Transform and Load data from ES to PSQL.

## Usage
```bash
docker run \
  -e ES_URL="http://my_elasticsearch_host:9200" \
  -e ES_INDEX_PATTERN='logstash-*' \
  -e CSV_TMPFILE_PATH=/tmp/esdump.csv \
  -e CSV_SED_CMD="1s/prefix_to_remove\.//g ; 1s/@timestamp/timestamp/ ; 1s/kubernetes\.labels\.release/my_instance/ " \
  -e PG_HOST=my_database_host \
  -e PG_USER=my_database_user \
  -e PG_DATABASE=my_database_name \
  -e PG_PASSWORD=my_database_pass \
  -e PG_DDL_FILE=/tmp/table.sql \
  -e PG_SCHEMA_NAME=public \
  -e PG_TABLE_NAME=my_table \
  -e PG_TIME_FIELD=my_time_field \
  -e REFRESH_INTERVAL=3600 \
  -v $(pwd)/table.sql:/tmp/table.sql \
  tibkiss/es2postgres
```

## License
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

