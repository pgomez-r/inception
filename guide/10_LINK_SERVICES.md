# Link all services together - Volumes and Network

At this point we have each service working correctly by itself, but we are not finished quite yet, as some of them need to be connected to others. So, to finish the work, let's modify our docker-compose.yml to set this connections right.

Also, we will upgrade our Makefile again after all the work is done, adding some useful steps and rules.

## Step 1. Update nginx configuration to work with WordPress

When we firs set our nginx service, we left a basic version just to check that the server itself was working correclty. Now we need to change the configuration of nginx so that it processes only php files. To do this, we will remove any reference to html that we had before, replace them by php equivalent and uncomment the block that processes php.

Our updated `nginx.conf` file looks like this:

```
server {
    listen      443 ssl;
    server_name  <your_username>.42.fr www.<your_username>.42.fr;
    root    /var/www/;
    index index.php;
    ssl_certificate     /etc/nginx/ssl/<your_username>.42.fr.crt;
    ssl_certificate_key /etc/nginx/ssl/<your_username>.42.fr.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_session_timeout 10m;
    keepalive_timeout 70;
    location / {
        try_files $uri /index.php?$args;
        add_header Last-Modified $date_gmt;
        add_header Cache-Control 'no-store, no-cache';
        if_modified_since off;
        expires off;
        etag off;
    }
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
```

> Again, we will need to replace all <your_username> with an real 42 nickname to make it work.

### Version of the file with explanation comments:

```
# Define a server block to handle requests
server {
    # Listen on port 443 for HTTPS connections with SSL/TLS enabled
    listen      443 ssl;

    # Specify the server name (domain) that this block will respond to
    server_name  <your_username>.42.fr www.<your_username>.42.fr;

    # Define the root directory where the website files are stored
    root    /var/www/;

    # Set the default file to serve when a directory is requested
    index index.php;

    # Specify the path to the SSL certificate file
    ssl_certificate     /etc/nginx/ssl/<your_username>.42.fr.crt;

    # Specify the path to the SSL certificate private key file
    ssl_certificate_key /etc/nginx/ssl/<your_username>.42.fr.key;

    # Define the SSL protocols that are allowed (TLS 1.2 and 1.3)
    ssl_protocols       TLSv1.2 TLSv1.3;

    # Set the timeout for SSL sessions to 10 minutes
    ssl_session_timeout 10m;

    # Set the keepalive timeout to 70 seconds
    keepalive_timeout 70;

    # Define a location block to handle requests to the root URL path (/)
    location / {
        # Try to serve the requested file, if not found, pass the request to index.php with the query arguments
        try_files $uri /index.php?$args;

        # Add a custom header indicating the last modification date of the resource
        add_header Last-Modified $date_gmt;

        # Add a Cache-Control header to prevent caching of the content
        add_header Cache-Control 'no-store, no-cache';

        # Disable the If-Modified-Since header to prevent conditional requests
        if_modified_since off;

        # Disable expiration headers
        expires off;

        # Disable ETag headers
        etag off;
    }

    # Define a location block to handle requests for PHP files
    location ~ \.php$ {
        # Split the path info for FastCGI processing
        fastcgi_split_path_info ^(.+\.php)(/.+)$;

        # Pass the PHP requests to the FastCGI server (e.g., PHP-FPM) running on 'wordpress' at port 9000
        fastcgi_pass wordpress:9000;

        # Set the default index file for FastCGI
        fastcgi_index index.php;

        # Include the standard FastCGI parameters
        include fastcgi_params;

        # Set the SCRIPT_FILENAME parameter for FastCGI to the full path of the PHP script
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;

        # Set the PATH_INFO parameter for FastCGI to the additional path information
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
```

Now our configuration is finish and our nginx service is ready to serve our wordpress site to the localhost, let's move on.

## Step 2. Create and connect volumes and network

### Volumes

Docker volumes are a way to persist data and share it between containers or between a container and the host machine. Without volumes, when a container is stopped or deleted, all the data inside it is lost. Volumes allow you to store data outside the container, making it persistent and accessible even after the container is removed.

In this project, we are using *bind mounts*, which are a type of Docker volume that maps a specific directory on your host machine -your computer- to a directory inside the container. This allows for easy data sharing and persistence. Also, the subject requires the directory for storing all these volumes data to be located at `/home/<username>/data`.

For our services to work together, Nginx needs access to WordPress files (PHP scripts, themes, plugins...) to serve the website; and WordPress needs a place to store its data (posts, users, settings...), which is handled by MariaDB.

Then, we need to create two volumes:

- wp-volume: sharing files Nginx <--> WordPress

- db-volume: storing/modifying files WordPress <--> MariaDB

To set this volumes we need to declare them in `docker-compose.yml`, name them, use the `o: bind` and `type: none` options so they become bind mounts, and also include the path of the 'reference' directory on the host machine, for example:

```
volumes:
  wp-volume:
    driver_opts:
      o: bind
      type: none
      device: /home/${USER}/data/wordpress

  db-volume:
    driver_opts:
      o: bind
      type: none
      device: /home/${USER}/data/mariadb
```

How would this work when our services are built and running? On your host machine, Docker will have created -or used, if already existing- the directories, then those will be mapped to the appropriate directories inside the containers. 

During running time, each service will write and/or read from each directory as needed, and when you stop or delete the containers, the data in `/home/${USER}/data/wordpress` and `/home/${USER}/data/mariadb` will remain intact.

When you restart the containers, they will use the same data, ensuring your website and database are preserved.

### Network

Next, we need to combine our containers into a single network. In fact, all containers that are registered inside the same single docker-compose.yml file are automatically combined into a common default network. 

However, we cannot name or set any options to this network, so we will create our own for convenience, so it can be accesible to us by name -and also, because the subject requires to do so...-

```
networks:
    inception:
        driver: bridge
```

## Updated docker-compose.yml

Let's update our docker-compose.yml to reflect the new volumes and the network in the containers that need to. We will do this by adding or uncommenting service dependencies and options - remember that some of them were previously left to do-. Also, I am going to reorder the services so they follow the dependency order: mariadb(no dependecy) - wordpress(depens on mariadb) - nginx(depens on wordpress).

Our new file will look like this:

```
version: '3'

services:
  mariadb:
    build:
      context: ./requirements/mariadb
      dockerfile: Dockerfile
      args:
        DB_NAME: ${DB_NAME}
        DB_USER: ${DB_USER}
        DB_PASS: ${DB_PASS}
        DB_ROOT: ${DB_ROOT}
    container_name: mariadb
    ports:
      - "3306:3306"
    networks:
      - inception
    volumes:
      - db-volume:/var/lib/mysql
    restart: on-failure

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
    networks:
      - inception
    volumes:
      - wp-volume:/var/www/
    restart: on-failure

  nginx:
    build:
      context: ./requirements/nginx
      dockerfile: Dockerfile
    container_name: nginx
    depends_on:
     - wordpress
    ports:
      - "443:443"
    networks:
     - inception
    volumes:
      - ./requirements/nginx/conf/:/etc/nginx/http.d/
      - ./requirements/nginx/tools:/etc/nginx/ssl/
    restart: on-failure

volumes:
  wp-volume:
    driver_opts:
      o: bind
      type: none
      device: /home/${USER}/data/wordpress

  db-volume:
    driver_opts:
      o: bind
      type: none
      device: /home/${USER}/data/mariadb

networks:
    inception:
        driver: bridge
```

## Step 3. Updating the Makefile

### Create a script that generates the data folder

When running a Makefile, we need to check for the existence of the directories we need, and if they don't exist, then create them. A simple script will do this. Let's put it, for example, in the wordpress/tools folder:

Also, do not forget to copy our Makefile. It will have to be changed a bit, because docker-compose is on the srcs path. This imposes certain restrictions on us, because by making a make on the directory above, we will not pick up our secrets (the system will search.env in the same directory where the Makefile is located). Therefore, we indicate to our docker-compose not only the path to ./srcs, but also the path to .env. This is done by specifying the --env-file flag.:

```
name = inception
all:
	@printf "Launch configuration ${name}...\n"
  @bash srcs/requirements/wordpress/tools/make_dir.sh
	@docker-compose -f ./srcs/docker-compose.yml --env-file srcs/.env up -d --build

down:
	@printf "Stopping configuration ${name}...\n"
	@docker-compose -f ./srcs/docker-compose.yml --env-file srcs/.env down

re: down
	@printf "Rebuild configuration ${name}...\n"
	@docker-compose -f ./srcs/docker-compose.yml --env-file srcs/.env up -d --build

clean: down
	@printf "Cleaning configuration ${name}...\n"
	@docker system prune -a
	@sudo rm -rf ~/data/wordpress/*
	@sudo rm -rf ~/data/mariadb/*

fclean:
	@printf "Total clean of all configurations docker\n"
	@docker stop $$(docker ps -qa)
	@docker system prune --all --force --volumes
	@docker network prune --force
	@docker volume prune --force
	@sudo rm -rf ~/data/wordpress/*
	@sudo rm -rf ~/data/mariadb/*

.PHONY	: all build down re clean fclean
```

I advise you to do a make clean before saving it to the cloud.

***

The project is deployed `make build", the stop is `make down", the start after the stop is `make`, etc`

This completes the main part of the project. After configuring wordpress, the project can be submitted. You also need to save all the sources to the repository and be able to correctly deploy your project from them.

# Step 4. Checking if all the configuration is working properly

So, after we run `docker-compose u --build` in our `~/project/srcs" directory, we will observe the configuration build for a while. And finally, we will find that everything is assembled and working.:

![настройка wordpress](media/docker_wordpress/install_all.png)

Just in case, we will check the functionality of the configuration. Let's run a few commands. First, listen to the php socket:

``docker exec -it wordpress ps aux | grep 'php'``

The output should be as follows:

```
    1 root      0:00 {php-fpm8} php-fpm: master process (/etc/php8/php-fpm.conf
    9 nobody    0:00 {php-fpm8} php-fpm: pool www
   10 nobody    0:00 {php-fpm8} php-fpm: pool www
```

Then let's see how php works, having found out the version:

``docker exec -it wordpress php -v``

```
PHP 8.0.22 (cli) (built: Aug  5 2022 23:54:32) ( NTS )
Copyright (c) The PHP Group
Zend Engine v4.0.22, Copyright (c) Zend Technologies
```

Finally, let's check if all the modules are installed.:

``docker exec -it wordpress php -m``

```
[PHP Modules]
Core
curl
date
dom
exif
fileinfo
filter
hash
json
libxml
mbstring
mysqli
mysqlnd
openssl
pcre
readline
Reflection
SPL
standard
xml
zip
zlib

[Zend Modules]
```

... and voila! - the settings panel opens in front of us:

![настройка wordpress](media/docker_wordpress/welcome.png)
