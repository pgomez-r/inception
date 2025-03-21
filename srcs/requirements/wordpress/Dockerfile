# OS base image
FROM alpine:3.18

# Arguments needed by the image building process
ARG PHP_VERSION=82
ARG DB_NAME
ARG DB_USER
ARG DB_PASS
ARG DOMAIN_NAME
ARG WP_USER
ARG WP_PASS

# Install php and its main packages
# Install wget and unzip
# Clean cache after installation
# All this is a single line commmand, you can display as you prefer for better readability
RUN apk update && apk upgrade && apk add --no-cache \
    php${PHP_VERSION} php${PHP_VERSION}-fpm php${PHP_VERSION}-phar \
    php${PHP_VERSION}-mysqli php${PHP_VERSION}-json \
    php${PHP_VERSION}-curl php${PHP_VERSION}-dom php${PHP_VERSION}-exif \
    php${PHP_VERSION}-fileinfo php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-openssl php${PHP_VERSION}-xml php${PHP_VERSION}-zip \
    php${PHP_VERSION}-redis wget unzip && apk del --no-cache && rm -rf /var/cache/apk/*

# Modify PHP-FPM configuration
RUN sed -i "s|listen = 127.0.0.1:9000|listen = 9000|g" /etc/php${PHP_VERSION}/php-fpm.d/www.conf && \
    sed -i "s|;listen.owner = nobody|listen.owner = nobody|g" /etc/php${PHP_VERSION}/php-fpm.d/www.conf && \
    sed -i "s|;listen.group = nobody|listen.group = nobody|ig" /etc/php${PHP_VERSION}/php-fpm.d/www.conf

# Set working directory
WORKDIR /var/www/html

# Download, unzip wordpress latest version (check on website and change according)
# Move wordpress folder to working directry (/var/www/htm)
# Remove the .zip file that you don't need any more, keeping the image lighter
RUN wget -O wordpress.zip https://wordpress.org/wordpress-6.5.2.zip && \
    unzip wordpress.zip && \
    cp -rf wordpress/* . && \
    rm -rf wordpress wordpress.zip

# Copy script from project folder to image, which will be used to generate the wp-config.php
COPY ./requirements/wordpress/conf/wp-config.sh .

# Execute script, remove it after and give all persmissions to wp-content folder
RUN sh wp-config.sh && rm wp-config.sh && \
    chmod -R 0777 wp-content/

# Script to automate the installation of WordPress and setup of necessary services
COPY ./requirements/wordpress/conf/wp-setup.sh .
RUN sh wp-setup.sh && rm wp-setup.sh

EXPOSE 9000

# Start php-fpm service in the foreground
CMD ["sh", "-c", "/usr/sbin/php-fpm82 -F"]