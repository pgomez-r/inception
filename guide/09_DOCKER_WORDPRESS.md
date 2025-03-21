# Creating a wordpress container

For a general understanding, let's do a small review of the task, breaking it down into subtasks.

First, let's write out a list of what we need for the container:

- PhP with plugins for wordpress
- PhP-fpm for communication with nginx
- Wordpress itself

To get all done, we will need to perform the following steps:

- In Dockerfile: install php + plugins
- In Dockerfile: download and install wordpress at /var/www
- Insert the correct fastcgi config into the container (www.conf )
- Run a fastcgi container via a php-fpm socket
- Add all necessary partitions to docker-compose
- Set the order of container launch
- Add a wordpress section to an nginx container

## Step 1. Setting up the Dockerfile

``vim requirements/wordpress/Dockerfile``

First, check the latest version of php in the official site https://www.php.net to specify it in Dockerfile `FROM`.

Then, we will pass several arguments `ARG` from our .env file to the Dockerfile: the version of php -to make easier to install all extensions of the same version-, the database info -name, user and pass-, the domain name for our website and another user for wordpress, aside from the 'owner' -admin- of the site, which will be the same as the database owner.

All these variables will be needed during the building of the image, specially for the scripts that will expand them to set the configurations and setup for wordpress.

> Remember to add whatever of these variables to `inception/src/.env` if you do not have them yet, for example the second wordpress user:
``WP_USER=rick
WP_PASS=1234``

Then, we install the basic php components: php itself, php-fpm for interacting with nginx and php-mysqli for interacting with mariadb.

```
FROM alpine:3.18
ARG PHP_VERSION=82
ARG DB_NAME
ARG DB_USER
ARG DB_PASS
ARG DOMAIN_NAME
ARG WP_USER
ARG WP_PASS

RUN apk update && apk upgrade && apk add --no-cache \
    php${PHP_VERSION} \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-mysqli
```

Now let's check the wordpress documentation at the server environmnet section (https://make.wordpress.org/hosting/handbook/server-environment/) so we can see what packages we may need to install for Wordpress to work correctly, which would be:

- A web server; which we already have (nginx)

- PhP

- PhP extensions recommended, such as **curl, openssl, redis**...

- A database such as MariaDB -also, we already have that-.

If you read the full documentation page, you will notice that many php extensions packages are recommended; we are going to install only some of them. For the bonus part, we will also install the redis module -if not sure about doing the bonus part yet, you can install it aynway, it will do no harm-. We will also download the wget package needed to download wordpress itself, and the unzip package to unzip the archive with the downloaded wordpress.

> All this takes place in a single command line, using `RUN`. Why? Well, it would be more readable to write many `RUN` lines in our Dockerfile -and the final result will be the same-, but if you remember what we explain before, each command of Dockerfile adds a new layer to the image, then, the more layers, the bigger our image gets. Yes, the difference may be just some MBs, but it is a good practice keeping the image as lighter as possible, especially when building bigger projects.

This would be our Dockerfile so far:

```
FROM alpine:3.18

ARG PHP_VERSION=82
ARG DB_NAME
ARG DB_USER
ARG DB_PASS
ARG DOMAIN_NAME
ARG WP_USER
ARG WP_PASS

RUN apk update && apk upgrade && apk add --no-cache \
    php${PHP_VERSION} php${PHP_VERSION}-fpm php${PHP_VERSION}-phar \
    php${PHP_VERSION}-mysqli php${PHP_VERSION}-json \
    php${PHP_VERSION}-curl php${PHP_VERSION}-dom php${PHP_VERSION}-exif \
    php${PHP_VERSION}-fileinfo php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-openssl php${PHP_VERSION}-xml php${PHP_VERSION}-zip \
    php${PHP_VERSION}-redis wget unzip && rm -rf /var/cache/apk/*
```

The next step is to modify wordpress configuration as we need. We will edit www.conf file so our fastcgi listens to all connections on port 9000.

> TODO: check if need to ufw enable + vbox portforwarding?

The principle is the same as in the previous guide, we will use the `sed` command to change some specific lines of the config default file.

> **Path /etc/php8/php-fpm.d/ depends on the installed php version!! You can use a variable PHP_VERSION or make sure of the path and specify it**

```
RUN sed -i "s|listen = 127.0.0.1:9000|listen = 9000|g" /etc/php${PHP_VERSION}/php-fpm.d/www.conf && \
    sed -i "s|;listen.owner = nobody|listen.owner = nobody|g" /etc/php${PHP_VERSION}/php-fpm.d/www.conf && \
    sed -i "s|;listen.group = nobody|listen.group = nobody|ig" /etc/php${PHP_VERSION}/php-fpm.d/www.conf
```

Next, we need to download wordpress and unzip it along the path /var/www/. For convenience, we will make this a working path with the `WORKDIR` dockerfile commmand.

After assigning a working directory, we download the latest version of wordpress with wget, unzipp it, and delete all the source files.

Next, we will copy and execute our configuration script, which will create the file `wp-config.php` and fill it with our desired cofiguration, as well as getting the information about or mariadb database. We will delete this script once finished and give full permissions to the wp-conten folder so that our CMS can download themes, plugins, save images and other files.

Then, we do the same with another script, this one will automate the installation of WordPress and will setup the necessary services.

> We will see both scripts in more detail later in this same guide section.

Finally, expose the port and set CMD to run our installed php-fpm **(attention! the version must match the installed one!)**

```
WORKDIR /var/www
RUN wget https://wordpress.org/latest.zip && \
    unzip latest.zip && \
    cp -rf wordpress/* . && \
    rm -rf wordpress latest.zip
COPY ./requirements/wordpress/conf/wp-config-create.sh .
RUN sh wp-config-create.sh && rm wp-config-create.sh && \
    chmod -R 0777 wp-content/
CMD ["/usr/sbin/php-fpm8", "-F"]
```

### Full Dockerfile example commented
```
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
# All this is a single line commmand, you can display as you prefer for better readability
RUN apk update && apk upgrade && apk add --no-cache \
    php${PHP_VERSION} php${PHP_VERSION}-fpm php${PHP_VERSION}-phar \
    php${PHP_VERSION}-mysqli php${PHP_VERSION}-json \
    php${PHP_VERSION}-curl php${PHP_VERSION}-dom php${PHP_VERSION}-exif \
    php${PHP_VERSION}-fileinfo php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-openssl php${PHP_VERSION}-xml php${PHP_VERSION}-zip \
    php${PHP_VERSION}-redis wget unzip && rm -rf /var/cache/apk/*

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
COPY ./requirements/wordpress/conf/wp-config-create.sh .

# Execute script, remove it after and give all persmissions to wp-content folder
RUN sh wp-config-create.sh && rm wp-config-create.sh && \
    chmod -R 0777 wp-content/

# Script to automate the installation of WordPress and setup of necessary services
# COPY ./requirements/wordpress/conf/wp-config-create.sh .
# RUN sh wp-config-create.sh && rm wp-config-create.sh && \
#     chmod -R 0777 wp-content/

EXPOSE 9000

# Start php-fpm service in the foreground
CMD ["sh", "-c", "/usr/sbin/php-fpm82 -F"]
```

## Step 2. Configuration of docker-compose

Now let's add a wordpress service to our docker-compose following the same basic pattern to start, as we have done before:

```
  wordpress:
    build:
      context: ./requirements/wordpress
      dockerfile: Dockerfile
    container_name: wordpress
    depends_on:
      mariadb:
       condition: service_healthy
    restart: on-failure
```

The `depends_on` directive means that wordpress depends on mariadb, and will not start until the database container is assembled. We need to ensure this because wordpress will need the database to be fully created in order to work correctly.

Even using `depends_on`, both services MariaDB and WP may be built and assembled at about the same time, so in order to make really sure this will not happen, adding the condition `service_healthy` it is also a good practice.

> *Also, it helps to organize the docker-compose file in the desired order of building: mariadb(no dependency) - wordpress(depends on mariadb) - nginx(depends on wordpress)*

Next, we will pass the evironment variables to the container as arguments:

```
  wordpress:
    build:
      context: ./requirements/wordpress
      dockerfile: Dockerfile
      args:
        DB_NAME: ${DB_NAME}
        DB_USER: ${DB_USER}
        DB_PASS: ${DB_PASS}
    container_name: wordpress
    depends_on:
      mariadb:
       condition: service_healthy
    restart: on-failure
```

## Step 3. Worpdress pre-configuration script

We will need to copy our own configuration file to the wordpress folder, which will also connect to the database. We will do so by creating a script that will insert the lines into the desired file.

``
mkdir inception/srcs/requirements/wordpress/conf

vim inception/srcs/requirements/wordpress/conf/wp-config.sh
``

Basically, what the script needs to do is:
- Checks if /var/www/wp-config.php exists (in case we already set it, to avoid rewritting it)
- If not, it creates the file and populates it with the WordPress configuration.
- It pulls database credentials from environment variables.
- It sets Redis caching settings - **BONUS**
- Finally, it includes wp-settings.php to complete the WordPress setup.

Here is an example of a script to this, with explaining comments:

```
#!/bin/sh

# Check if the WordPress configuration file does not exist
if [ ! -f "/var/www/wp-config.php" ]; then

# Create the wp-config.php file using a here document
cat << EOF > /var/www/wp-config.php
<?php
# Define the database name, using an environment variable
define( 'DB_NAME', '${DB_NAME}' );

# Define the database user, using an environment variable
define( 'DB_USER', '${DB_USER}' );

# Define the database password, using an environment variable
define( 'DB_PASSWORD', '${DB_PASS}' );

# Define the database host (assumed to be a MariaDB instance)
define( 'DB_HOST', 'mariadb' );

# Define the database character set
define( 'DB_CHARSET', 'utf8' );

# Define the database collation (empty means default collation is used)
define( 'DB_COLLATE', '' );

# Set the file system method to direct to avoid FTP prompts
define('FS_METHOD','direct');

# Set the database table prefix for WordPress
\$table_prefix = 'wp_';

# Disable WordPress debugging
define( 'WP_DEBUG', false );

# Set the absolute path to the WordPress directory
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

# Redis caching configuration - BONUS
define( 'WP_REDIS_HOST', 'redis' );  # Redis server hostname
define( 'WP_REDIS_PORT', 6379 );     # Redis server port
define( 'WP_REDIS_TIMEOUT', 1 );    # Connection timeout in seconds
define( 'WP_REDIS_READ_TIMEOUT', 1 );  # Read timeout in seconds
define( 'WP_REDIS_DATABASE', 0 );   # Redis database index

# Include WordPress settings and bootstrap the application
require_once ABSPATH . 'wp-settings.php';
EOF

fi
```

> *Let's pay attention to `\$table_prefix = 'wp_';` The backslash - "\\" is used so shell will not interpret `$table_prefix` as a varaible to be expanded -which would result in an empty string-. `$table_prefix` is meant meant for PHP, not the shell*

> Redis related settings will be useful to us *only* in the bonus part. They won't bother us with the main one either.

## Step 4. WordPress installation and setup script

If we would only do the pre-configuration of WordPress, using the previous script, our CMS will have the essential data and info to be working properly, but the website itself would not be displayable yet. In that scenario, once the container is built and running, the first time we open our domain in a browser we would be welcomed by WordPress Installation Wizard -the installation page- that would ask us to set some info, such as admin email, site title, etc.

This is not totally wrong, we could set the page the first time in this manner, but it is forbidden by the subject... So, let's do the same with a script that will be executed in the building of the image itself, which will automate the installation of WordPress and setup of necessary services.

The main steps of the script:
- Check for WP-CLI: The script first checks if WP-CLI (/usr/local/bin/wp) is already installed.
- Download and Install WP-CLI: If WP-CLI is not found, it downloads and installs it.
- Install WordPress: It uses WP-CLI to install WordPress, specifying configurations such as the site URL, admin - credentials, and WordPress path.
- Create a WordPress User: It creates a new user with a specified role and credentials.

Here is an example of a script to this, with explaining comments:

```
#!/bin/sh

# Check if WP-CLI is already installed by verifying the existence of /usr/local/bin/wp
if [ ! -f "/usr/local/bin/wp" ]; then  # If the file /usr/local/bin/wp does not exist

    # Download the WP-CLI (WordPress Command Line Interface) PHAR file from GitHub and save it to /usr/local/bin/wp
    wget -O /usr/local/bin/wp https://github.com/wp-cli/builds/raw/gh-pages/phar/wp-cli-release.phar

    # Make the downloaded wp-cli file executable by changing its permissions
    chmod +x /usr/local/bin/wp

    # Install WordPress using WP-CLI with various configuration options:
    # - --allow-root allows the root user to run the WP-CLI commands
    # - --url=$DOMAIN_NAME sets the site URL to the value of the DOMAIN_NAME environment variable
    # - --title="pgomez-r inception" sets the site title to "pgomez-r inception"
    # - --admin_user=$DB_USER uses the DB_USER environment variable for the admin username
    # - --admin_password=$DB_PASS uses the DB_PASS environment variable for the admin password
    # - --admin_email="yourmail@gmail.com" sets the admin email address
    # - --path="/var/www/html" specifies the directory where WordPress should be installed (default web directory)
    wp core install --allow-root --url=$DOMAIN_NAME --title="your_login inception site" --admin_user=$DB_USER --admin_password=$DB_PASS --admin_email="yourmail.11@gmail.com" --path="/var/www/html"

    # Create a new WordPress user using WP-CLI:
    # - $WP_USER is the environment variable containing the desired username for the new user
    # - guest@example.com is the email address for the new user
    # - --role=author assigns the "author" role to the new user, which allows them to write and publish posts
    # - --user_pass=$WP_PASS sets the password for the new user (from the WP_PASS environment variable)
    # - --allow-root allows the root user to run this command
    wp user create $WP_USER guest@example.com --role=author --user_pass=$WP_PASS --allow-root

fi

```

Congratulations, we have completed the installation and configuration of our wordpress. Now let's move to the last section of the guide about mandatory part, where we will connect all services, volumes and network.

