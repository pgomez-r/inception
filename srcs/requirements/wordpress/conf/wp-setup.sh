#!/bin/sh

# Check if PHP is installed
if ! command -v php > /dev/null 2>&1; then
    echo "PHP is not installed. Exiting."
    exit 1
fi

echo "Creating setup with the following values:"
echo "DB_NAME: ${DB_NAME}"
echo "DB_USER: ${DB_USER}"
echo "DB_PASS: ${DB_PASS}"

# Wait for MariaDB to be ready
MAX_RETRIES=10
RETRY_COUNT=0
until mysql -h mariadb -u${DB_USER} -p${DB_PASS} -e "SHOW DATABASES;" > /dev/null 2>&1; do
    RETRY_COUNT=$((RETRY_COUNT+1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "MariaDB is not ready after $MAX_RETRIES attempts. Exiting."
        echo "Debug Info: Host=mariadb, User=${DB_USER}, Pass=${DB_PASS}"
        mysql -h mariadb -u${DB_USER} -p${DB_PASS} -e "SHOW DATABASES;"  # Run the command without redirecting output to see the error
        exit 1
    fi
    echo "Waiting for MariaDB to be ready... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 5
done

echo "MariaDB is ready. Proceeding with WordPress setup."

# Run WordPress CLI commands
wp core install --allow-root --url=$DOMAIN_NAME --title="pgomez-r inception" --admin_user=$DB_USER --admin_password=$DB_PASS --admin_email="pedrogruz.11@gmail.com" --path="/var/www/html"
if [ $? -ne 0 ]; then
    echo "Error: wp core install failed."
    exit 1
fi

wp user create $WP_USER guest@example.com --role=author --user_pass=$WP_PASS --allow-root
if [ $? -ne 0 ]; then
    echo "Error: wp user create failed."
    exit 1
fi

echo "WordPress setup completed successfully."
