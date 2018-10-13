FROM postgres:10.5

MAINTAINER Jacob Salmela <jacob.salmela@pi-hole.net>

RUN apt-get update && \
    apt-get install -y postgresql-pltcl-10

ADD main.sql /docker-entrypoint-initdb.d/
