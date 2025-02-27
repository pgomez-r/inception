NAME = inception

all:
@printf "Setting configuration for ${name}...\n"
	@docker-compose -f ./docker-compose.yml up -d

build:
	@printf "Building ${name}...\n"
	@docker-compose -f ./docker-compose.yml up -d --build

down:
	@printf "Stopping ${name}...\n"
	@docker-compose -f ./docker-compose.yml down

re:	down
	@printf "Reassembling ${name} configuration...\n"
	@docker-compose -f ./docker-compose.yml up -d --build

clean: down
	@printf "Clearing the configuration of ${name}...\n"
	@docker system prune -a

fclean:
@printf "Complete cleanup of all docker configurations\n"
	@docker stop $$(docker ps -qa)
	@docker system prune --all --force --volumes
	@docker network prune --force
	@docker volume prune --force

.PHONY	: all build down re clean fclean
