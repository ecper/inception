FROM alpine:3.21

RUN apk update && apk add --no-cache \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-json \
    php83-curl \
    php83-dom \
    php83-exif \
    php83-fileinfo \
    php83-mbstring \
    php83-openssl \
    php83-xml \
    php83-zip \
    php83-redis \
    php83-phar \
    wget \
    tar \
    mysql-client

RUN sed -i 's/listen = 127.0.0.1:9000/listen = 9000/g' /etc/php83/php-fpm.d/www.conf && \
    sed -i 's/;listen.owner = nobody/listen.owner = nobody/g' /etc/php83/php-fpm.d/www.conf && \
    sed -i 's/;listen.group = nobody/listen.group = nobody/g' /etc/php83/php-fpm.d/www.conf && \
    sed -i 's/;clear_env = no/clear_env = no/g' /etc/php83/php-fpm.d/www.conf && \
    echo 'php_admin_value[memory_limit] = 256M' >> /etc/php83/php-fpm.d/www.conf

RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

WORKDIR /var/www/html

COPY conf/wp-config-docker.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wp-config-docker.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/wp-config-docker.sh"]

CMD ["/usr/sbin/php-fpm83", "-F"]