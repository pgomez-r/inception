NAME = inception

all:
	@mkdir -p /home/${USER}/data
	@mkdir -p /home/${USER}/data/mariadb
	@mkdir -p /home/${USER}/data/wordpress
	@printf "Building and setting configuration for ${NAME}...\n"
	@docker-compose -f srcs/docker-compose.yml --env-file srcs/.env up -d --build

down:
	@printf "Stopping ${NAME}...\n"
	@docker-compose -f srcs/docker-compose.yml down

clean: down
	@printf "Stopping and cleaning up all docker configurations of ${NAME}...\n"
	@docker system prune -a

fclean:
	@printf "Cleaning all configuration of ${NAME} and both volumes and host data...\n"
	@if [ -n "$$(docker ps -qa)" ]; then docker stop $$(docker ps -qa); fi
	@docker system prune --all --force --volumes
	@docker network prune --force
	@docker volume prune --force
	@docker image prune --all --force
	@docker container prune --force
	@docker builder prune --all --force
	@if [ -n "$$(docker volume ls -q)" ]; then docker volume rm $$(docker volume ls -q); fi
	@if [ -d "/home/${USER}/data" ]; then sudo rm -rf /home/${USER}/data; fi

re:	clean
	@mkdir -p /home/${USER}/data
	@mkdir -p /home/${USER}/data/mariadb
	@mkdir -p /home/${USER}/data/wordpress
	@printf "Reassembling ${NAME} configuration...\n"
	@docker-compose -f srcs/docker-compose.yml --env-file srcs/.env up -d --build

.PHONY	: all build down re clean fclean
