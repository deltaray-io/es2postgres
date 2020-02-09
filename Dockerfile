FROM python:2.7.17-slim-buster 

ARG ES2CSV_SHA=4397ccbf3c195c7a294f5fca5bac559799a72f0c
ARG XSV_URL=https://github.com/BurntSushi/xsv/releases/download/0.13.0/xsv-0.13.0-x86_64-unknown-linux-musl.tar.gz

ENV DEBIAN_FRONTEND=noninteractive
RUN \
  apt-get update && \
  apt-get install -y --no-install-recommends curl git postgresql-client && \
  pip install git+git://github.com/tibkiss/es2csv.git@${ES2CSV_SHA}#egg=es2csv && \
  curl -L ${XSV_URL} | tar xvz -C /usr/bin && \
  rm -rf /var/lib/apt/lists

ADD es2postgres.sh /

ENTRYPOINT ["/es2postgres.sh"]
