#!/bin/sh

sleep 10

# Set WP-CLI memory limit
export WP_CLI_PHP_ARGS="-d memory_limit=512M"

if [ ! -f /var/www/html/wp-config.php ]; then
    cd /var/www/html
    
    # Download WordPress directly with wget (more reliable)
    wget https://wordpress.org/latest.tar.gz
    tar xzf latest.tar.gz
    mv wordpress/* .
    rmdir wordpress
    rm latest.tar.gz
    
    # Create wp-config.php manually
    cp wp-config-sample.php wp-config.php
    
    # Update database configuration
    sed -i "s/database_name_here/$WORDPRESS_DB_NAME/g" wp-config.php
    sed -i "s/username_here/$WORDPRESS_DB_USER/g" wp-config.php
    sed -i "s/password_here/$WORDPRESS_DB_PASSWORD/g" wp-config.php
    sed -i "s/localhost/$WORDPRESS_DB_HOST/g" wp-config.php
    
    # Add salts
    SALT=$(wget -qO- https://api.wordpress.org/secret-key/1.1/salt/)
    sed -i "/put your unique phrase here/d" wp-config.php
    echo "$SALT" >> wp-config.php
    
    # Wait for database
    while ! mysqladmin ping -h mariadb -u $WORDPRESS_DB_USER -p$WORDPRESS_DB_PASSWORD --silent; do
        echo "Waiting for database..."
        sleep 5
    done
    
    # Try WP-CLI commands with retries
    retry_wp_command() {
        local cmd="$1"
        local retries=3
        while [ $retries -gt 0 ]; do
            if eval "$cmd"; then
                return 0
            else
                echo "Command failed, retrying... ($retries attempts left)"
                retries=$((retries - 1))
                sleep 5
            fi
        done
        echo "Command failed after all retries: $cmd"
        return 1
    }
    
    # Install WordPress
    retry_wp_command "wp core install \
        --url=https://$DOMAIN_NAME \
        --title='$WORDPRESS_TITLE' \
        --admin_user=$WORDPRESS_ADMIN_USER \
        --admin_password=$WORDPRESS_ADMIN_PASSWORD \
        --admin_email=$WORDPRESS_ADMIN_EMAIL \
        --skip-email \
        --allow-root"
    
    # Create regular user
    retry_wp_command "wp user create \
        $WORDPRESS_USER \
        $WORDPRESS_USER_EMAIL \
        --role=author \
        --user_pass=$WORDPRESS_USER_PASSWORD \
        --allow-root"
    
    # Set proper permissions
    chown -R nobody:nobody /var/www/html
    
    echo "WordPress installation completed!"
    echo "Admin user: $WORDPRESS_ADMIN_USER"
    echo "Regular user: $WORDPRESS_USER"
fi

exec "$@"