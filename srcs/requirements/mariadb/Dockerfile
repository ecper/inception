FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/mysqld \
    && chown -R mysql:mysql /var/run/mysqld \
    && chmod 777 /var/run/mysqld

EXPOSE 3306

COPY conf/create_db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/create_db.sh

ENTRYPOINT ["/usr/local/bin/create_db.sh"]

CMD ["/usr/sbin/mysqld", "--user=mysql", "--console", "--skip-networking=0", "--bind-address=0.0.0.0"]