NAME = inception

all:
	@mkdir -p /home/${USER}/data
	@mkdir -p /home/${USER}/data/mariadb
	@mkdir -p /home/${USER}/data/wordpress
	# @chown -R 1000:1000 /home/${USER}/data/mariadb
	# @chown -R 1000:1000 /home/${USER}/data/wordpress
	# @chmod -R 755 /home/${USER}/data/mariadb
	# @chmod -R 755 /home/${USER}/data/wordpress
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
	@docker stop $$(docker ps -qa)
	@docker system prune --all --force --volumes
	@docker network prune --force
	@docker volume prune --force
	@docker image prune --all --force
	@docker container prune --force
	@docker builder prune --all --force
	@docker volume rm $(docker volume ls -q)
	@sudo rm -rf ~/data

re:	clean
	@mkdir -p /home/${USER}/data
	@mkdir -p /home/${USER}/data/mariadb
	@mkdir -p /home/${USER}/data/wordpress
	@printf "Reassembling ${NAME} configuration...\n"
	@docker-compose -f srcs/docker-compose.yml --env-file srcs/.env up -d --build

.PHONY	: all build down re clean fclean
