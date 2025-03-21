#!/bin/sh

# Check if PHP is installed
if ! command -v php > /dev/null 2>&1; then
    echo "PHP is not installed. Exiting."
    exit 1
fi

# Wait for MariaDB to be ready
MAX_RETRIES=6
RETRY_COUNT=0
until mysql -h mariadb -u${DB_USER} -p${DB_PASS} -e "SHOW DATABASES;" > /dev/null 2>&1; do
    RETRY_COUNT=$((RETRY_COUNT+1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "MariaDB is not ready after $MAX_RETRIES attempts. Exiting."
		exit 1
    fi
    echo "Waiting for MariaDB to be ready... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 5
done

echo "MariaDB is ready. Proceeding with WordPress setup."

if [ ! -f "/usr/local/bin/wp" ]; then
    wget -O /usr/local/bin/wp https://github.com/wp-cli/builds/raw/gh-pages/phar/wp-cli-release.phar
    chmod +x /usr/local/bin/wp

    echo "Running wp core install..."
    wp core install --allow-root --url=$DOMAIN_NAME --title="pgomez-r inception" --admin_user=$DB_USER --admin_password=$DB_PASS --admin_email="pedrogruz.11@gmail.com" --path="/var/www/html"
    if [ $? -ne 0 ]; then
        echo "Error: wp core install failed."
        exit 1
    fi

    echo "Creating WordPress user..."
    wp user create $WP_USER guest@example.com --role=author --user_pass=$WP_PASS --allow-root
    if [ $? -ne 0 ]; then
        echo "Error: wp user create failed."
        exit 1
    fi
fi

echo "WordPress setup completed successfully."