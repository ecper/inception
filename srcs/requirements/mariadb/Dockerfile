FROM alpine:3.21

RUN apk update && apk add --no-cache mariadb mariadb-client

RUN mkdir -p /var/run/mysqld \
    && chown -R mysql:mysql /var/run/mysqld \
    && chmod 777 /var/run/mysqld

EXPOSE 3306

COPY conf/create_db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/create_db.sh

ENTRYPOINT ["/usr/local/bin/create_db.sh"]

CMD ["/usr/bin/mysqld", "--user=mysql", "--console", "--skip-networking=0", "--bind-address=0.0.0.0"]