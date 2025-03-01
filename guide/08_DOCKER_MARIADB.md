# Creating a Mariadb container

## Step 1. Create the Dockerfile for MariaDB

Let's set our MariaDB service. This is a intial folder and files structure:

![mariadb setup](media/docker_mariadb/step_0.png)

What we need to do to set this container up is basically to install MariaDB package and client, create both MariaDB and MySQL configuration files and write a MySQL script that creates a database that will be used later by WordPress.

Here is a brief step-by-step for this Dockerfile, listed as ``KEYWORD`` : Idea:
- ``FROM`` : Get OS system image (as always).
- ``RUN`` : Install mariadb and mariadb client.
- ``RUN`` : Create MySQL socket directory
- ``RUN`` : Configure MariaDB
- ``RUN`` : Init MariaDB
- ``EXPOSE`` : Port to be used
- ``COPY`` : Copy mySQL script
- ``ENTRYPOINT`` : Set entrypoint
- ``CMD`` : Start mySQL server

Now, let's see a version of the full Dockerfile with comments to explain a bit deeper what is going on in each step:

``
# OS base image
FROM alpine:3.16

# Declare build arguments (these will be passed from .env by docker-compose.yml)
ARG DB_NAME
ARG DB_USER
ARG DB_PASS

# Install MariaDB (update package index first and install both mariadb and client without cache)
RUN apk update && apk add --no-cache mariadb mariadb-client

# Create MySQL socket directory with correct permissions
# chown command sets ownership of the folder /var/run/mysqld to MariaDB (which it 'mysql' user)
RUN mkdir -p /var/run/mysqld && chown mysql:mysql /var/run/mysqld

# Configure MariaDB
# Directory '/etc/my.cnf.d' should exists after MariDB installation, but just in case, we can create it otherwise
# Echo writes the configuration into 'docker.cnf' file, using '\n' to have each option in newline
# 'docker.cnf' should not exist before this command, but if so, its content will be overwritten, so no worries there =)
RUN mkdir -p /etc/my.cnf.d && echo '[mysqld]\nskip-host-cache\nskip-name-resolve\nbind-address=0.0.0.0' > /etc/my.cnf.d/docker.cnf

# Disable skip-networking; needed in order to allow remote connections to the database (from another containers, for instance...)
# 'skip-networking' is a MariaDB/MySQL config option that disables all TCP/IP connections to the database and onlys allow local connections through Unix sockets
# Thus, we need to make sure this configuration is DISABLED
# We find and comment that option in '/etc/my.cnf.d/mariadb-server.cnf', using sed command with -i flag (modify file) and syntax 's/SEARCH/REPLACE/'
RUN sed -i 's/^skip-networking/#skip-networking/' /etc/my.cnf.d/mariadb-server.cnf

# Init MariaDB database: this command initializes a new MariaDB database by setting up the necessary files and system tables
# mysql_install_db creates basic structure of the database, as well as default tables
# --user==mysql flag ensures that all database files are owned by the mysql user
# --datadir=/var/lib/mysql flag tells MariaDB where to store its data, /var/lib/mysql is the default location tipaclly
RUN mariadb-install-db --user=mysql --datadir=/var/lib/mysql

# Informs Docker that the container will listen on port 3306 (MySQL default)
EXPOSE 3306

# Copy database setup script, which has been previosly stored in '/tools'
COPY tools/db.sh .

# Set entry point, which ensures that db.sh will be executed when the containers starts
ENTRYPOINT ["sh", "db.sh"]

# Start MySQL server
CMD ["/usr/bin/mysqld", "--skip-log-error"]
``

> The order of the lines in Dockefile is important, remember that they excute in descending order, adding "layers" or configurations to our image, so obviously you cannot change the permissions of a directory before creating that directory (silly simple example, sorry)

After Dockerfile is built, the image will have the directory `/var/lib/mysql`, which will have contain:

/var/lib/mysql/
│-- mysql/                 # System database (user accounts, privileges, etc.)
│-- performance_schema/     # Performance-related data
│-- information_schema/     # Metadata about databases
│-- ibdata1                # InnoDB system tablespace
│-- ib_logfile0, ib_logfile1 # InnoDB log files
│-- aria_log.*             # Aria storage engine logs
│-- *.frm, *.ibd, *.MYD, *.MYI # Table definitions and data


## Step 2. Script for creating a database

Now, our Dockerfile need a script that will copy when building at will be executed when the container starts. This script will create a mySQL database, let's get into it:

`vim requirements/mariadb/tools/db.sh`

Let's write the following code into it:

```
#!/bin/sh

# Check MySQL database exists
if [ ! -d "/var/lib/mysql/mysql" ]; then

    echo "Initializing MariaDB data directory..."
    chown -R mysql:mysql /var/lib/mysql

    # Initialize the database
    mysql_install_db --basedir=/usr --datadir=/var/lib/mysql --user=mysql --rpm

    tfile=$(mktemp)
    if [ ! -f "$tfile" ]; then
        echo "Error: Failed to create temp file."
        exit 1
    fi
fi

# Check if WordPress database exists
if [ ! -d "/var/lib/mysql/wordpress" ]; then
    echo "Creating database and user..."

    cat << EOF > /tmp/create_db.sql
USE mysql;
FLUSH PRIVILEGES;

DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test';

DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT}';

CREATE DATABASE ${DB_NAME} CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    # Run SQL script to set up the database
    /usr/bin/mysqld --user=mysql --bootstrap < /tmp/create_db.sql
    rm -f /tmp/create_db.sql
fi
```

The first block of the script checks if mysql is loaded and running, just in case something is not ok, but our MySQL server must be installed and running already, so this block will most probably always skipped.

(Need to understand and rephrase this paragraph...)
The second block claims that it only works using wordpress. Of course you're not, and when I add myself to the internal block, I write a file for sql queries of the sql code to create the database in a special section 1.2. Use the environment variables that we represent. In the same block, we execute this code and delete the extra configuration file, skillfully covering our tracks like real trutskers.

## Step 3. Environment variables - Execute the script

For the script to work, and the database to be created and functional, we need to pass the environment variables to the container. 

Environment variables are always kept separated from the project code, especially on open-code projects, for security reasons, and the subject do remids you this several times.

In docker, there are several ways to pass or parse the .env variables to the container image. In this case, we chose to parse the variables in the Dockerfile, while the docker-compose will pass them to it from .env as arguments, that is why we had this at the beggining of the Dockerfile:

```
# Dockerfile
# Declare build arguments (these will be passed from the environment but NOT saved in the image)
ARG DB_NAME
ARG DB_USER
ARG DB_PASS
```

## Step 4. Configuration of docker-compose

We continue to edit our docker-compose.yml, taking into account what we said about .env variables before.

```
  mariadb:
    build:
      context: .
      dockerfile: mariadb/Dockerfile
      args:
        DB_NAME: ${DB_NAME}
        DB_USER: ${DB_USER}
        DB_PASS: ${DB_PASS}
        DB_ROOT: ${DB_ROOT}
    container_name: mariadb
    ports:
      - "3306:3306"
    restart: always
```
As we can see, our permals are passed to ARG through the args section in the build section. They can only be transmitted here, because they are launched only during the build and are not present in the image, unlike ENV, which are transmitted through the environment section already inside the service.

Let's not forget to mount the partition in the same way so that the database status is not reset after each container restart.:

```
    volumes:
      - db-volume:/var/lib/mysql
```

Mariadb is running on port 3306, so this port must be open.

The entire docker-compose file:

```
version: '3'

services:
  nginx:
    build:
      context: .
      dockerfile: requirements/nginx/Dockerfile
    container_name: nginx
#    depends_on:
#      - wordpress
    ports:
      - "443:443"
    volumes:
      - ./requirements/nginx/conf/:/etc/nginx/http.d/
      - ./requirements/nginx/tools:/etc/nginx/ssl/
      - /home/${USER}/simple_docker_nginx_html/public/html:/var/www/
    restart: always

  mariadb:
    build:
      context: .
      dockerfile: requirements/mariadb/Dockerfile
      args:
        DB_NAME: ${DB_NAME}
        DB_USER: ${DB_USER}
        DB_PASS: ${DB_PASS}
        DB_ROOT: ${DB_ROOT}
    container_name: mariadb
    ports:
      - "3306:3306"
    volumes:
      - db-volume:/var/lib/mysql
    restart: always
```
## Step 5. Checking the database operation

In order to check if everything has worked out, we need to run the following command after starting the container:

``docker exec -it mariadb mysql -u root``

This way we will find ourselves in the text environment of the database.:

``MariaDB [(none)]> ``

Here we enter the command

``show databases;``

In our case, the output should be as follows:

```
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| wordpress          |
+--------------------+
5 rows in set (0.001 sec)
```
There must be a database created by us with the name `wordpress` at the bottom! If it doesn't exist, then our script worked incorrectly or didn't work at all. This may be due to a variety of reasons - the script file was not copied, the environment variables were not passed, and the wrong values are written in the .env file...

But if everything is done correctly, congratulations - we have successfully launched the database!

Exit the environment with the exit command or Ctrl+D.

