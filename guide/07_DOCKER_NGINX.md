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

```nano Dockerfile```

And we write in it the FROM instruction, which indicates from which image we will deploy our container. By subject, we are prohibited from specifying labels like alpine:latest, which are automatically assigned to the latest versions of alpine in the dockerhub repositories. Therefore, we go to the [official website](https://www.alpinelinux.org / "alpine versions") of the system and see which is the latest release. At the time of writing the guide, it was alpine 3.21, but for the FROM instructions, it will be enough to specify the younger version.:

```FROM alpine:3.21```

More information about Dockerfile instructions can be found in [this video](https://www.youtube.com/watch?v=wskg5903K8I "docker by Anton Pavlenko"), here we will analyze just a few of them.

Next, we specify which software and how we want to install it inside the container. The RUN instruction will help us with this.

The `RUN` instruction creates a new image layer with the result of the called command, similar to how the snapshot system saves changes in a virtual machine. Actually, the image itself consists of this kind of layers of changes.

It is not possible to launch the application directly from `RUN`. In some cases, this can be done through a script, but in general, the `CMD` and `ENTRYPOINT` instructions are used to run. 
`RUN` creates a static layer, changes inside which are written to the image, but do not cause anything. 
`CMD` and `ENTRYPOINT` run something, but DO NOT WRITE changes to the image. Therefore, it is not necessary to execute scripts with them.

We can say that the changes made through `RUN` are static. For example, installing packages in a system is usually done like this:

```RUN	apk update && apk upgrade && apk add --no-cache nginx```

Here we tell the apk file manager to update the list of its repositories in search of the latest software versions (apk update), update outdated packages in our environment (apk upgrade) and install nginx without storing the source code in the cache (apk add --no-cache nginx). It works almost exactly like `apt` in debian.

Then we need to open the port where the container will exchange traffic.:

```EXPOSE 443```

Eventually we have to run the installed configuration. To do this, use the instruction ``CMD``:

```CMD ["nginx", "-g", "daemon off;"]```

This way we run nginx directly, rather than in daemon mode. Daemon mode, on the other hand, is a startup mode in which an application starts in the background, or as in Windows equivalence, a service. For the convenience of debugging, we disable this mode and receive all nginx logs directly into the tty(?) of the container.

```
FROM alpine:3.16
RUN	apk update && apk upgrade && apk add --no-cache nginx
EXPOSE 443
CMD ["nginx", "-g", "daemon off;"]
```
That's actually the whole Dockerfile. Simple, isn't it?

Save, close.

## Step 3. Create a configuration file

Naturally, our nginx won't work without a configuration file. Let's write it!

Let's create our config folder and config file for nginx at its directory (on project/requirements/nginx):

```
mkdir conf
vim conf/nginx.conf
```

Since we have already trained with the test container, we will take a similar configuration, changing it for php so that it allows reading wordpress php files instead of html. We will no longer need port 80, since according to the guide we can only use port 443. But at the first stage, we will comment out the sections responsible for php and temporarily add html support (for verification):

```
server {
    listen      443 ssl;
    server_name  <your_nickname>.42.fr www.<your_nickname>.42.fr;
    root    /var/www/;
    index index.php index.html;
    ssl_certificate     /etc/nginx/ssl/<your_nickname>.42.fr.crt;
    ssl_certificate_key /etc/nginx/ssl/<your_nickname>.42.fr.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_session_timeout 10m;
    keepalive_timeout 70;
    location / {
        try_files $uri /index.php?$args /index.html;
        add_header Last-Modified $date_gmt;
        add_header Cache-Control 'no-store, no-cache';
        if_modified_since off;
        expires off;
        etag off;
    }
#    location ~ \.php$ {
#        fastcgi_split_path_info ^(.+\.php)(/.+)$;
#        fastcgi_pass wordpress:9000;
#        fastcgi_index index.php;
#        include fastcgi_params;
#        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
#        fastcgi_param PATH_INFO $fastcgi_path_info;
#    }
}
```

Port 9000 is the port of our php-fpm that connects php and nginx. And wordpress in this case is the name of our wordpress container. But for now, let's try to at least just run something on nginx.

Just copy it to our project and save the file.

And I use the tools folder for the keys by copying them there.:

```cp ~/project/srcs/requirements/tools/* ~/project/srcs/requirements/nginx/tools/```

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

Next, in the next indent level of the nginx service (again, spaces indentation) we specify the `build:` which will have several elements or propierties within (within one more indent level). For now add `context: .` (but do not worry about that for now) and let the docker-compose file know where the Dockerfile for nginx is located `dockerfile: requirements/...` 

```
version: '3'

services:
  nginx:
    build:
      context: .
      dockerfile: requirements/nginx/Dockerfile
```

We set a name for our container, as well as forward the required port (in this task we can only use ssl).

We will also describe the dependency, while commenting it out. We need nginx to start after wordpress, picking up its build. But nginx builds faster, and in order to avoid collisions, we need it to wait for the wordpress container to be built and run only after it. For now, we'll comment on this for tests.

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

We add sections so that the container sees our config and our keys, and we also make sure to mount our /var/www - the same folder from the old configuration that we will need for the nginx trial run. Later, we will delete it and take files from the wordpress directory.

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
```

Next, we specify the type of restart. In this case I am using "on failure":

```
    restart: on failure
```

And thus we have the following configuration:

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
    restart: on failure
```

In case you did not before, don't forget to turn off the test configuration.:

```cd ~/simple_docker_nginx_html/```

```docker-compose down```

And we launch our new configuration:

```cd ~/project/srcs/```

```docker-compose up -d```

Since we are using port 443, and it only supports https protocol, we will refer to the https address.:

``https://127.0.0.1 `` in the browser

``https://<your_nickname>.42.fr`` in GUI

And now, if we access the localhost from the browser, we get a working configuration.:

![nginx worker](media/install_certificate/step_10.png)

By easily replacing several docker-compose values and uncomenting the configuration file, we will get a working nginx that supports TLS and works with wordpress. But that is going to happen next.

In the meantime, we take snapshots, save ourselves in the cloud, pour a pleasant liquid for the body and enjoy life.
