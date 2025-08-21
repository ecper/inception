FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php7.4 \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-json \
    php7.4-curl \
    php7.4-dom \
    php7.4-exif \
    php7.4-fileinfo \
    php7.4-mbstring \
    php7.4-xml \
    php7.4-zip \
    php7.4-redis \
    wget \
    tar \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/listen = \/run\/php\/php7.4-fpm.sock/listen = 9000/g' /etc/php/7.4/fpm/pool.d/www.conf && \
    sed -i 's/;listen.owner = www-data/listen.owner = www-data/g' /etc/php/7.4/fpm/pool.d/www.conf && \
    sed -i 's/;listen.group = www-data/listen.group = www-data/g' /etc/php/7.4/fpm/pool.d/www.conf && \
    sed -i 's/;clear_env = no/clear_env = no/g' /etc/php/7.4/fpm/pool.d/www.conf && \
    echo 'php_admin_value[memory_limit] = 256M' >> /etc/php/7.4/fpm/pool.d/www.conf

RUN mkdir -p /run/php

RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

WORKDIR /var/www/html

COPY conf/wp-config-docker.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wp-config-docker.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/wp-config-docker.sh"]

CMD ["/usr/sbin/php-fpm7.4", "-F"]