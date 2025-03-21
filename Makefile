NAME = inception



all:
	@mkdir -p /home/${USER}/data/mariadb
	@mkdir -p /home/${USER}/data/wordpress
	@printf "Building and setting configuration for ${NAME}...\n"
	@docker-compose -f srcs/docker-compose.yml up -d --build

down:
	@printf "Stopping ${NAME}...\n"
	@docker-compose -f srcs/docker-compose.yml down

clean: down
	@printf "Stopping and cleaning up all docker configurations of ${NAME}...\n"
	@docker system prune --all --force --volumes
	@docker network prune --force
	@docker volume prune --force

fclean: down
	@printf "Cleaning all configuration of ${NAME} and both volumes and host data...\n"
	@docker system prune --all --force --volumes
	@docker network prune --force
	@docker volume prune --force
	@docker image prune --all --force
	@docker container prune --force
	@docker builder prune --all --force
	@sudo rm -rf ~/data/wordpress/*
	@sudo rm -rf ~/data/mariadb/*

re:	clean
	@mkdir -p /home/${USER}/data/mariadb
	@mkdir -p /home/${USER}/data/wordpress
	@printf "Reassembling ${NAME} configuration...\n"
	@docker-compose -f srcs/docker-compose.yml up -d --build

.PHONY	: all build down re clean fclean
