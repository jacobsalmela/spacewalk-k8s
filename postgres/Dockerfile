FROM postgres:10.5

MAINTAINER Jacob Salmela <jacob.salmela@pi-hole.net>

RUN apt-get update && \
    apt-get install -y postgresql-pltcl-10

# Install the main.sql file from a clean install of Spacewalk 2.9 so it populates the database correctly
ADD main.sql /docker-entrypoint-initdb.d/
