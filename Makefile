include .env
export

docker-install:
	# install docker
	@echo "⌛ Installing Docker ..."
	@curl -fsSL https://get.docker.com -o get-docker.sh
	sudo sh get-docker.sh
	@sudo usermod -aG docker pi
	# install docker-compose from python3-pip
	@echo "⌛ Installing Docker-compose ..."
	sudo apt install -y libffi-dev libssl-dev python3 python3-pip
	sudo pip3 install docker-compose

pivpn-install:
	@echo "⌛ Installing PiVPN ..."
	curl -L https://install.pivpn.io | bash

all: docker-install traefik-run pihole-run
	@echo "✅ All done and running"

pihole-run: pihole-install pihole-port
	@echo "✅ Pi-hole install done"

pihole-install:
	# pihole install
	@echo "⌛ Installing Pi-hole ..."
	curl -sSL https://install.pi-hole.net | bash
	# unbound install
	@echo "⌛ Installing Unbound ..."
	sudo apt install -y unbound
	@wget -O root.hints https://www.internic.net/domain/named.root
	@sudo mv root.hints /var/lib/unbound/
	@sudo cp pi-hole.conf /etc/unbound/unbound.conf.d/pi-hole.conf
	sudo service unbound start

pihole-port:
	# change pihole default port to 8080
	@sudo sed -i 's/80/8080/g' /etc/lighttpd/lighttpd.conf
	@sudo service lighttpd restart

pihole-up:
	# update pihole
	pihole -up

pihole-upgrade: pihole-up pihole-port
	@echo "✅ Pi-hole upgrade done"

traefik-run: traefik-setup traefik-rules traefik-up
	@echo "✅ Traefik service running"

traefik-setup:
	@mkdir -p $$DATA/shared
	@mkdir -p $$DATA/traefik/	
	# acme	
	@mkdir -p $$DATA/traefik/acme
	@touch $$DATA/traefik/acme/acme.json
	@chmod 600 $$DATA/traefik/acme/acme.json
	# logs
	@touch $$DATA/traefik/traefik.log
	# network
	@docker network create proxy
	# basic-auth (htpasswd)
	@sudo apt install -y apache2-utils
	@htpasswd -nb $$AUTH_USER $$AUTH_PASSWORD > $$DATA/shared/.htpasswd

traefik-rules:
	# rules
	@cp -r rules $$DATA/traefik/
	# edit rule secure-headers
	@sed -i "s/DOMAIN/$$DOMAIN/g" $$DATA/traefik/rules/secure-headers.yml
	# edit rule pihole
	@sed -i "s/DOMAIN/$$DOMAIN/g" $$DATA/traefik/rules/pihole.yml
	@sed -i "s/PIHOLEIP/$$PIHOLEIP/g" $$DATA/traefik/rules/pihole.yml

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

wireguard-up:
	docker-compose -f wireguard.yml --env-file=.env up -d
wireguard-logs:
	docker-compose -f wireguard.yml logs -f wireguard
wireguard-down:
	docker-compose -f wireguard.yml down