FROM postgres:10.11

MAINTAINER Jacob Salmela <me@jacobsalmela.com>

RUN apt-get update && \
    apt-get install -y postgresql-pltcl-10

# Install the main.sql file from a clean install of Spacewalk 2.10 so it populates the database correctly
ADD main.sql /docker-entrypoint-initdb.d/
