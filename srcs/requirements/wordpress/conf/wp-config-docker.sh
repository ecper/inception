#!/bin/sh

sleep 10

if [ ! -f /var/www/html/wp-config.php ]; then
    cd /var/www/html
    
    # Download WordPress directly
    wget https://wordpress.org/latest.tar.gz
    tar xzf latest.tar.gz
    mv wordpress/* .
    rm -rf wordpress latest.tar.gz
    
    # Create wp-config.php
    cp wp-config-sample.php wp-config.php
    
    # Update database configuration
    sed -i "s/database_name_here/$WORDPRESS_DB_NAME/g" wp-config.php
    sed -i "s/username_here/$WORDPRESS_DB_USER/g" wp-config.php
    sed -i "s/password_here/$WORDPRESS_DB_PASSWORD/g" wp-config.php
    sed -i "s/localhost/$WORDPRESS_DB_HOST/g" wp-config.php
    
    # Generate salts
    SALT=$(wget -qO- https://api.wordpress.org/secret-key/1.1/salt/)
    sed -i "/put your unique phrase here/d" wp-config.php
    echo "$SALT" >> wp-config.php
    
    # Set proper permissions
    chown -R nobody:nobody /var/www/html
fi

exec "$@"