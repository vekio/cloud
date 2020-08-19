include .env
export

all: docker pihole pivpn traefik
	@echo "✅ all up and running"

docker: docker-install docker-setup
	@echo "✅ docker up and running"

docker-install:
	@echo "⌛ install docker ..."
	@curl -fsSL https://get.docker.com -o get-docker.sh
	sudo sh get-docker.sh
	@sudo usermod -aG docker pi
	@echo "⌛ install docker-compose from pip3 ..."
	sudo apt install -y libffi-dev libssl-dev python3 python3-pip
	sudo pip3 install docker-compose

docker-setup:
	@echo "⌛ setup docker folder ..."
	@sudo setfacl -Rdm g:docker:rwx $$DOCKER
	@sudo chmod -R 775 $$DOCKER

pihole: pihole-install pihole-port
	@echo "✅ pi-hole up and running"

pihole-install:
	@echo "⌛ install pi-hole ..."
	curl -sSL https://install.pi-hole.net | bash
	@echo "⌛ install unbound ..."
	sudo apt install -y unbound
	@wget -O root.hints https://www.internic.net/domain/named.root
	@sudo mv root.hints /var/lib/unbound/
	@sudo cp pi-hole.conf /etc/unbound/unbound.conf.d/pi-hole.conf
	sudo service unbound start

pihole-port:
	@echo "⌛ change pi-hole web panel port ..."
	@sudo sed -i 's/80/8080/g' /etc/lighttpd/lighttpd.conf
	@sudo service lighttpd restart

pihole-up:
	pihole -up

pihole-update: pihole-up pihole-port
	@echo "✅ pi-hole update done"

pivpn: pivpn-install
	@echo "✅ pivpn up and running"

pivpn-install:
	@echo "⌛ install PiVPN ..."
	curl -L https://install.pivpn.io | bash

traefik: traefik-setup traefik-rules traefik-up
	@echo "✅ traefik up and running"

traefik-setup:
	@echo "⌛ create traefik folders ..."
	@mkdir -p $$DOCKER/shared
	@mkdir -p $$DOCKER/traefik/
	@mkdir -p $$DOCKER/traefik/acme
	@touch $$DOCKER/traefik/acme/acme.json
	@chmod 600 $$DOCKER/traefik/acme/acme.json
	@touch $$DOCKER/traefik/traefik.log
	@echo "⌛ docker network create proxy ..."
	@docker network create proxy
	@echo "⌛ create auth credentials ..."
	@sudo apt install -y apache2-utils
	@htpasswd -nb $$AUTH_USER $$AUTH_PASSWORD > $$DOCKER/shared/.htpasswd

traefik-rules:
	@echo "⌛ copy traefik rules ..."
	@cp -r rules $$DOCKER/traefik/
	@echo "⌛ edit traefik rules ..."
	@sed -i "s/DOMAIN/$$DOMAIN/g" $$DOCKER/traefik/rules/secure-headers.yml
	@sed -i "s/DOMAIN/$$DOMAIN/g" $$DOCKER/traefik/rules/pihole.yml
	@sed -i "s/PIHOLEIP/$$PIHOLEIP/g" $$DOCKER/traefik/rules/pihole.yml

traefik-up:
	docker-compose -f traefik.yml --env-file=.env up -d
traefik-logs:
	docker-compose -f traefik.yml logs -f traefik
traefik-down:
	docker-compose -f traefik.yml down

portainer-up:
	docker-compose -f portainer.yml --env-file=.env up -d
portainer-logs:
	docker-compose -f portainer.yml logs -f portainer
portainer-down:
	docker-compose -f portainer.yml down

bitwarden-up:
	docker-compose -f bitwarden.yml --env-file=.env up -d
bitwarden-logs:
	docker-compose -f bitwarden.yml logs -f bitwarden
bitwarden-down:
	docker-compose -f bitwarden.yml down

duckdns-up:
	docker-compose -f duckdns.yml --env-file=.env up -d
duckdns-logs:
	docker-compose -f duckdns.yml logs -f duckdns
duckdns-down:
	docker-compose -f duckdns.yml down

jellyfin-up:
	docker-compose -f jellyfin.yml --env-file=.env up -d
jellyfin-logs:
	docker-compose -f jellyfin.yml logs -f jellyfin
jellyfin-down:
	docker-compose -f jellyfin.yml down
