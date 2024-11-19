FROM postgres:latest

RUN apt-get -y update && \
    apt-get -y dist-upgrade && \
    apt-get -y upgrade

RUN chown -R postgres:postgres /docker-entrypoint-initdb.d/ && chmod +x /docker-entrypoint-initdb.d/

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["postgres"]
