# Creating NIGNX container

So we took a snapshot, saved the configuration to the cloud or to a USB stick, and are ready to start deploying containers directly to the project.

First, let's get some knowledge of the technologies that we will use in our containers.

The following scheme is given in our assignment:

![nginx configuration](media/nginx_deploy/step_1.png)

Let's see what kind of software we need to implement what is shown in the diagram.:

Technology | Purpose | The Creator | Ports
------ | ------ | ------ | ------ | 
Nginx | Proxying web server | Igor Sysoev (Russia) | 443 |
PHP	| Scripting language for the web | Rasmus Lerdorf (Denmark) | - |
Php-Fpm | Set of libraries for FastCGI API | Andrey Nigmatulin (Russia) | 9000 |
Wordpress | Content Management System | Matthew Mullenweg (USA) | - |
MariaDB | Relational database | Mikael Videnius (Finland) | 3306 |
---

- Nginx is largely considered to be the best proxying web server.

- PHP was created  in 1995, it quickly gained popularity in web development and is still one of the leading languages for the web.

- The php-fpm library has become the standard API between php and web servers, including Nginx. This is what we will use to make our nginx and php to get along. It is installed in a container with php.

- Wordpress is an easy-to-set up CMS (creation and modification of digital content) system which will help us to design wbesites "easily".

- MariaDB is a lightweight MySQL database analog.

So, let's start configuring the server with Nginx.

## Step 1. Introduction to Docker

A docker image is a set of environments required to run certain software. It differs from virtualbox-type emulators in that the container does not contain a full operating system, the container uses the Linux kernel and not everything is placed inside it, but only the programs and libraries necessary to run the software.

Thus, the container weighs significantly less than the emulated system. Let's see this clearly. Let's see how much our OS weighs when installed.:

![nginx configuration](media/nginx_deploy/step_2.png)

And let's compare this with the same image of the eleventh debian on [Docker Hub](https://hub.docker.com / "docker hub") - the official Docker image repository:

![nginx configuration](media/nginx_deploy/step_3.png)

The image weighs only 50 MB in compressed form (the compressed Debian disk weighed 950 MB!). After unpacking, this image will weigh about 150 MB. That's such a significant difference. And this is far from the limit.

That's because you don't need a full operating system to run a separate software, just a working kernel and some environment made up with all the dependencies - modules, libraries, packages, and scripts.

We will use the lightweight alpine system, which is used for containers and microcontrollers, but can also be installed in an emulator or on real hardware. The system is extremely light in weight: about 50 megabytes with the core, 30 megabytes unpacked and 2.5 megabytes compressed:

![nginx configuration](media/nginx_deploy/step_7.png)

The difference between the compressed format and debian is as much as 20 times! This was achieved by optimizing everything and everything, but it also imposes limitations. So the system uses a lightweight apk instead of the usual apt, there is no full-developed bash, sh is used instead, of course, [its own set of repositories] (https://pkgs.alpinelinux.org/packages "alpine package list") and many other features.

However, as with any open-source linux, a lot can be added here. And it is this distr that has become the main one for many docker projects due to its low weight, high speed and high fault tolerance. The larger and more complex the system, the more points of failure, which means that lightweight distributions have great advantages in this case.

So, when we have finished the review and figured out the difference between virtual machine and containers, we proceed to study how Docker works.

## Step 2. Create a Dockerfile

In Docker, a special file called Dockerfile is responsible for the configuration. It prescribes a set of software that we want to deploy inside this container.

Go to the folder of our nginx:

```cd ~/project/srcs/requirements/nginx/```

Creating a Dockerfile in it:

```vim Dockerfile```

And we write in it the FROM instruction, which indicates from which image we will deploy our container. By subject, we are prohibited from specifying labels like alpine:latest, which are automatically assigned to the latest versions of alpine in the dockerhub repositories. Therefore, we go to the official website of the system you chose and see which is the latest release.

```FROM debian:bullseye```

More information about Dockerfile instructions can be found in [this video](https://www.youtube.com/watch?v=wskg5903K8I "docker by Anton Pavlenko"), here we will analyze just a few of them.

Next, we specify which software and how we want to install it inside the container. The RUN instruction will help us with this.

The `RUN` instruction creates a new image layer with the result of the called command, similar to how the snapshot system saves changes in a virtual machine. Actually, the image itself consists of this kind of layers of changes, which are written to the image, but do not execute anything -despite its name-, `CMD` and `ENTRYPOINT` do run something, but DO NOT WRITE changes to the image. A bit confusing at first, yes.

We can say that the changes made through `RUN` are static and it is like the setup we do at first in a VM, installing packages and setting configuration files, as a container is essentially a super-light VM. For example, installing nginx and ceritifacte packages in the container could be done like this:

```RUN apt-get update && apt-get install -y nginx openssl ca-certificates```

Other way to set or change configurations in a container image is to copy files into in when building:

```COPY conf/nginx.conf /etc/nginx/sites-available/default```

That would place a file that we configured before and have stored in our project folder before deploy, although we could also create and write the file directly in the building process with something like:

```RUN echo 'whatever_config_content_we_need' > etc/nginx/sites-available/default/nginx.conf` ```

Then we need to expose the port where the container will exchange traffic:

```EXPOSE 443```

Just to easily test if the service is working, we will add a simple .html file to be served by nginx, so we can display in localhost when the container is up and running -not part of the subject, we will change it later-:

```COPY index.html /var/www/html/index.html```

At the end we have to run the installed configuration. To do this, use the instruction ``CMD``:

```CMD ["nginx", "-g", "daemon off;"]```

This way we run nginx directly, rather than in daemon mode. Daemon mode, on the other hand, is a startup mode in which an application starts in the background, or as in Windows equivalence, a service. For the convenience of debugging, we disable this mode and receive all nginx logs directly into the tty of the container (-g flag).

Here is an example of a initial version of Dockerfile for nginx:

```
# OS base image
FROM debian:bullseye

# Install nginx package, plus openssl and ca-certificates so we can read/use our .crt and .key
RUN apt-get update && apt-get install -y nginx openssl ca-certificates

# Set nginx configuration by copying our own .conf file in default configuration directory
COPY conf/nginx.conf /etc/nginx/sites-available/default

# Copy our certificates into nginx ssl certificates directory
# Alternative: create the certificates at the very moment of building the image, by running the commands to do so
COPY tools/pgomez-r.42.fr.crt /etc/nginx/ssl/pgomez-r.42.fr.crt
COPY tools/pgomez-r.42.fr.key /etc/nginx/ssl/pgomez-r.42.fr.key

# Copy a basic index.html in the index directory used by our config, so we can test if the server is workig
# We will change this later, when wordpress is set and working
COPY index.html /var/www/html/index.html

EXPOSE 443

# CMD to be executed when docker-compose, to run nginx without daemon "mode"
CMD ["nginx", "-g", "daemon off;"]
```

To do some testing later, add a `index.html` file just in /nginx folder, and add some message to it:

``` echo "<h1>Nginx is working!</h1>" > index.html```

## Step 3. Create a configuration file

Naturally, our nginx won't work without a configuration file. We need to create a config file in our project so Dockerfile can copy it to the image and place it in the right target directory when building.

``mkdir conf && vim conf/nginx.conf``

Here is an example of a working **-or should be working-** nginx.conf file, with explaning comments:

```
# Define a server block to handle requests
server {
    # Listen on port 443 for HTTPS connections with SSL/TLS enabled
    listen      443 ssl;

    # Specify the server name (domain) that this block will respond to
    server_name  <your_username>.42.fr www.<your_username>.42.fr;

    # Define the root directory where the website files are stored
    root    /var/www/html;

    # Set the default file to serve when a directory is requested
    index index.html; # Change this to index.php when WordPress is ready

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
        # Set the default file to serve when a directory is requested
        index index.html; # TODO: Change this to index.php when WordPress is ready

        # Try to serve the requested file, if not found, pass the request to index.html with the query arguments
        try_files $uri /index.html?$args; # TODO: Change to index.php when WordPress is ready

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

# The following block is commented out and will be used later for PHP (WordPress) processing
#        location ~ \\.php$ {
#            fastcgi_split_path_info ^(.+\.php)(/.+)$;
#            fastcgi_pass wordpress:9000;
#            fastcgi_index index.php;
#            include fastcgi_params;
#            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
#            fastcgi_param PATH_INFO $fastcgi_path_info;
#        }
}

```

> (!) Remember to replace <your_username> for your actual 42intra login

Again, this example will not be the final version, for now we will use a index.html so we can easily check if the service is properly build and running correctly. Later on, we will have to modify this to work with wordpress (php), so we will comment out the sections responsible for php and temporarily add html support.

> Later, on [guide 10](https://github.com/pgomez-r/inception/tree/main/guide/10_LINK_SERVICES.md "Link Services"), we will provide a final version of this configuration file, for now we should not worry much about it as long as the server itself works with our simple html file.

## Step 4. Creating the docker-compose configuration

Docker-compose is a docker container launch system, which can be said to be a kind of add-on to docker. If we specified in docker files which software to install inside a single container environment, then with docker-compose we can manage the launch of many similar containers at once, launching them with a single command.

To do this we must edit our already created docker-compose.yml file in the root of our project.


First, we register the version. The latest version is the third one.

```
version: '3'

services:
  nginx:
```

nginx will be the first in the list of our services. We put two spaces (**not tabs(!)**) and write the service name.

Next, in the next indent level of the nginx service (again, spaces indentation) we specify the `build:` which will have several elements or propierties within (within one more indent level). 

`context` is kind of your workspace root directory, the path from where to start to look for the Dockerfile and files needed by this. Then you can specify the Dockerfile in that directory `dockerfile: Dockerfile`. If you use '.' as context, your root will be the folder where `docker-compose.yml` is placed, in our case `srcs`; this could be helpful to have access to all service folders from any Dockerfile -e.g., nginx Dockerfile may need COPY files from wordpress/-

```
version: '3'

services:
  nginx:
    build:
      context: .
      dockerfile: requirements/nginx/Dockerfile
```

We set a name for our container, as well as forward the required port (in this task we can only use ssl).

We will also describe the dependency, while commenting it out. We need nginx to start after wordpress, picking up its build. But nginx builds faster, and in order to avoid collisions, we need it to wait for the wordpress container to be built and run only after it. For now, we'll comment on this as we don't have wordpress yet, also we will see ways to ensure the depens on function with more options.

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
```

We add sections so that the container sees our config and our keys, and we also make sure to mount our /var/www/html - the same folder from the old configuration that we will need for the nginx trial run. Later, we will delete it and take files from the wordpress directory.

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
```

Next, we specify the type of restart. In this case I am using "on failure":

```
    restart: on failure
```

Thi is an example of our temporary docker-compose.yml file. This time, I chose to use modular context, so each docker-compose only has acces to its service folder, as I trust with network and volumes should be enough to use needed files between containers, hope me luck with that...

```
version: '3'

services:
  nginx:
    build:
      context: ./requirements/nginx
      dockerfile: Dockerfile
    container_name: nginx
    ports:
      - "443:443"
  #  depends_on:
  #    - wordpress
    volumes:
      - ./requirements/nginx/conf/:/etc/nginx/http.d/
      - ./requirements/nginx/tools:/etc/nginx/ssl/
    restart: on-failure
```

In case you did not before, don't forget to turn off the test configuration.:

```docker-compose down```

And we launch our new configuration:

```cd ~/project/srcs/```

```docker-compose build nginx```

```docker-compose up -d nginx```

Now, try to open in browser:

``https://127.0.0.1 `` or ``https://<your_username>.42.fr``

And now, if we access the localhost from the browser, we get a working configuration.:

![nginx worker](media/install_certificate/step_10.png)

By easily replacing several docker-compose values and uncomenting the configuration file, we will get a working nginx that supports TLS and works with wordpress. But that is going to happen next.

In the meantime, we take snapshots, save ourselves in the cloud, pour a pleasant liquid for the body and enjoy life.
