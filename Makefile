name = inception

all:
	@mkdir -p /home/uchida/data/wordpress
	@mkdir -p /home/uchida/data/mariadb
	@docker compose -f ./srcs/docker-compose.yml up -d --build

down:
	@docker compose -f ./srcs/docker-compose.yml down

re:
	@docker compose -f ./srcs/docker-compose.yml down
	@docker compose -f ./srcs/docker-compose.yml up -d --build

clean:
	@docker compose -f ./srcs/docker-compose.yml down --rmi all
	@docker system prune -f

fclean:
	@docker compose -f ./srcs/docker-compose.yml down --volumes --rmi all
	@sudo rm -rf /home/uchida/data/wordpress
	@sudo rm -rf /home/uchida/data/mariadb
	@docker system prune -a -f --volumes

logs:
	@docker compose -f ./srcs/docker-compose.yml logs

.PHONY: all re down clean fclean logs