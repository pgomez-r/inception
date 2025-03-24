#!/bin/sh

# Verify WP-CLI is installed
if ! command -v wp > /dev/null 2>&1; then
    echo "Error: WP-CLI (wp command) is not installed"
    exit 1
fi

# Verify WordPress files exist
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Error: WordPress files not found in /var/www/html"
    exit 1
fi

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
MAX_RETRIES=5
RETRY_COUNT=0
until mysql -h mariadb -u"${DB_USER}" -p"${DB_PASS}" -e "USE ${DB_NAME};" 2>/dev/null; do
    RETRY_COUNT=$((RETRY_COUNT+1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "Error: Could not connect to MariaDB after $MAX_RETRIES attempts"
        echo "Trying command: mysql -h mariadb -u${DB_USER} -p[hidden] -e \"USE ${DB_NAME};\""
        mysql -h mariadb -u"${DB_USER}" -p"${DB_PASS}" -e "USE ${DB_NAME};"
        exit 1
    fi
    echo "Waiting for MariaDB... (attempt $RETRY_COUNT/$MAX_RETRIES)"
    sleep 5
done


echo "Database ready. Proceeding with WordPress setup..."

# Run WordPress CLI commands
wp core install --allow-root \
    --url="$DOMAIN_NAME" \
    --title="pgomez-r inception" \
    --admin_user="$DB_USER" \
    --admin_password="$DB_PASS" \
    --admin_email="pedrogruz.11@gmail.com" \
    --path="/var/www/html"
if [ $? -ne 0 ]; then
    echo "Error: wp core install failed."
    exit 1
fi

#Create WordPress second user (not admin)
wp user create "$WP_USER" "guest@example.com" \
    --role=author \
    --user_pass="$WP_PASS" \
    --allow-root
if [ $? -ne 0 ]; then
    echo "Error: wp second user create failed."
    exit 1
fi

echo "WordPress setup completed successfully."
