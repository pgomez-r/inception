## Getting ready for evaluation

> (!) Work in progress...

A list of tests to be checked before you set the project as finished and submit it for evaluation. In order to gather these, I have inspected both subject and evaluation requirements and then included any tests or cases that came to my mind while doing so.

- [ ] The project must be deployed on a VM
- [ ] Folder tree inception/ -all files in srcs/ except from Makefile-

        ```
                Makefile
                srcs/
                    (.env) # This file MUST not be in intra git(!)
                    docker-compose.yml
                    requirements/
                        mariadb/
                        nginx/
                        wordpress/
        ```
- [ ] Makefile must deploy the entire environment and application with one single command -could be just `make` or you can name it as you want to-; Makefile will use docker-compose.yml to do this.
- [ ] Each Docker image must have the same name as its corresponding service - Check in docker-compose.yml field `container_name`
- [ ] Dockerfiles have to been written by the student itself; it is forbidden to use ready-made ones or to use services such as the ones in DockerHub - #TODO how to check this?
- [ ] Each service has to run in a dedicated container - Check in docker-compose that there are three separated blocks inside `service:`, one per service 
- [ ] Containers must be built from either the penultimate stable version of Alpine or Debian - check in each Dockerfile that: 1) FROM uses either ALPINE or DEBIAN; 2) The version used in each case is the penultimate stable version according to official site of the OS
- [ ] There must be one Dockerfile per service - Check the folder tree to see that each service folder has one only Dockerfile

Mandatory Docker containers, volumes and network:
- [ ] Docker container that contains NGINX with TLSv1.2 or TLSv1.3 only
- [ ] Docker container that contains WordPress with php-fpm (it must be installed
and configured) only, *without nginx*
- [ ] Docker container that contains only MariaDB, *without nginx*
- [ ] A volume that contains your WordPress database
- [ ] A second volume that contains your WordPress website files
- [ ] A docker-network that establishes the connection between your containers

- [ ] Containers must restart automatically in case of a crash - # TODO: Find a way to test this
- [ ] Any use of `tail -f` and similar methods when running containers are *forbidden* - Try to `find in folder` for srcs/ with the words `tail -f`, if any found, project evaluation is failed
- [ ] Using `network: host` or `--link` or `links:` in docker-compose.yml is forbidden - Again, try to search on file or find in folder for any occurencies
- [ ] Containers must not be started with a command running an infinite loop; this also applies to any command used as entrypoint, or used in entrypoint scripts - To check all of this, `find in folder` at srcs/ for the words `tail -f`, `bash`, `sleep infinity`, `while true`
- [ ] In your WordPress database, there must be two users - one admin, other non-admin
- [ ] WP administrator’s username must not contain ’admin’, ’Admin’, ’administrator’, or ’Administrator’ (e.g., admin, administrator, Administrator, admin-123, etc) - #TODO: Find a way to check this
- [ ] Local volumes will be available at `/home/<your_username>/data` folder of the host machine (the VM) - Once everything is built and running, execute the command `docker volume ls` and verify that the path `/home/<your_username>/data` is present
- [ ] Your domain name -pointing at localhost IP address- must be `<your_username>.42.fr`. Again, you must use
- [ ] The `latest` tag is prohibited - Check this by searching on file or finding in folder for any occurencies of it
- [ ] The use of environment variables is mandatory - Check that docker-compose.yml and Dockerfile(s) handle and use them
- [ ] Passwords must not be present in your Dockerfiles - Search on each Dockerfile for any occurencies of 'pass', 'password', 'secret', 'key', and so on and verify that in those occurencies, the value of the variables are passed as env variables or arguments.
- [ ] Environment variables, secrets, keys, certificates or any other confidential information *must be kept outside the git repository* uploaded to the intra for evaluation - Search on the repository for '.env', 'cert', 'key'...
- [ ] NGINX service must be the sole entry point into your infrastructure - #TODO Find a way to test this
- [ ] You website has to be accessible only via port 443 - Try to specify a different port like `<your_username>.42.fr:4242`, you should not be able to view the site
- [ ] Your site must use TLSv1.2 or TLSv1.3 protocol - On browser navigation bar, click on the lock icon at the left side, you can view the certificate info there, check that it is one of those two
- [ ] Before starting the evaluation, run this command in the terminal: `docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker network rm $(docker network ls -q) 2>/dev/null` - # TODO - Find more info about this
- [ ] If there is entrypoint that it is a script (e.g., ENTRYPOINT ["sh", "my_entrypoint.sh"], ENTRYPOINT ["bash", "my_entrypoint.sh"]), ensure it runs no program, only scripts are allowed, no programs to run in the background (e.g, ENTRYPOINT ['nginx & bash'] would be forbidden). - find in folder for ENTRYPOINT and verify
- [ ] Ensure that WordPress website is properly installed and configured before the submission of the project (you shouldn't see the WordPress Installation page when opening the site, no matter if you do `make re`)
- [ ] You should not be able to access the project website via hhtp://, when you try this the browser should either send an error or redirect to https://. In case you can see the website, verify the navigation bar and the address, as probably the second scenario happened (redirection) 
- [ ] Once all built and running, check with the command `docker compose ps` and ensure all containers are created and running correctly. Wait a couple of minutes and check it again -some containers must take that time to finish all its configuration, and could have crashed while doing so-
- [ ] WP - Sign in with the administrator account to access Administration dashboard, from there edit a page. Verify on the website that the page has been updated with the changes - Try for example to change web elements colors or text.
- [ ] WP - Non-registred user -viewer of the site- can't send comments.
- [ ] WP - Admin vs Non-Admin - login with non-admin, she/he cannot edit website or approved/delete comments; login with admin and verify that this user can edit website and aprrove comments, along with all other admin privileges
- [ ] *PERSISTENCE* - Reboot the virtual machine. Once it has restarted, launch docker compose again. Then, verify that everything is functional, and that both WordPress and MariaDB are configured. The changes you made previously to the WordPress website should still be here. If any of the above points is not correct, the evaluation process ends now.


