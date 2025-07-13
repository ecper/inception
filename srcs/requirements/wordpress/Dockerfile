FROM alpine:3.18

RUN apk update && apk add --no-cache \
    php81 \
    php81-fpm \
    php81-mysqli \
    php81-json \
    php81-curl \
    php81-dom \
    php81-exif \
    php81-fileinfo \
    php81-mbstring \
    php81-openssl \
    php81-xml \
    php81-zip \
    php81-redis \
    php81-phar \
    wget \
    tar

RUN sed -i 's/listen = 127.0.0.1:9000/listen = 9000/g' /etc/php81/php-fpm.d/www.conf && \
    sed -i 's/;listen.owner = nobody/listen.owner = nobody/g' /etc/php81/php-fpm.d/www.conf && \
    sed -i 's/;listen.group = nobody/listen.group = nobody/g' /etc/php81/php-fpm.d/www.conf && \
    sed -i 's/;clear_env = no/clear_env = no/g' /etc/php81/php-fpm.d/www.conf && \
    echo 'php_admin_value[memory_limit] = 256M' >> /etc/php81/php-fpm.d/www.conf

WORKDIR /var/www/html

COPY conf/wp-config-docker.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wp-config-docker.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/wp-config-docker.sh"]

CMD ["/usr/sbin/php-fpm81", "-F"]