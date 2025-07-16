#!/bin/sh

sleep 10

if [ ! -f /var/www/html/wp-config.php ]; then
    cd /var/www/html
    
    # Download WordPress
    wp core download --allow-root
    
    # Create wp-config.php
    wp config create \
        --dbname=$WORDPRESS_DB_NAME \
        --dbuser=$WORDPRESS_DB_USER \
        --dbpass=$WORDPRESS_DB_PASSWORD \
        --dbhost=$WORDPRESS_DB_HOST \
        --dbcharset="utf8" \
        --dbcollate="" \
        --allow-root
    
    # Install WordPress
    wp core install \
        --url=$DOMAIN_NAME \
        --title="$WORDPRESS_TITLE" \
        --admin_user=$WORDPRESS_ADMIN_USER \
        --admin_password=$WORDPRESS_ADMIN_PASSWORD \
        --admin_email=$WORDPRESS_ADMIN_EMAIL \
        --skip-email \
        --allow-root
    
    # Create regular user (author role)
    wp user create \
        $WORDPRESS_USER \
        $WORDPRESS_USER_EMAIL \
        --role=author \
        --user_pass=$WORDPRESS_USER_PASSWORD \
        --allow-root
    
    # Set theme
    wp theme install twentytwentythree --activate --allow-root
    
    # Set proper permissions
    chown -R nobody:nobody /var/www/html
    
    echo "WordPress installation completed!"
    echo "Admin user: $WORDPRESS_ADMIN_USER"
    echo "Regular user: $WORDPRESS_USER"
fi

exec "$@"