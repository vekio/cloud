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

all: docker-install traefik pihole
	@echo "✅ All done"

pihole: pihole-install pihole-port pihole-rule
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

pihole-rule:
	# edit traefik rule
	@sed -i "s/DOMAIN/$$DOMAIN/g" $$DATA/traefik/rules/pihole.yml
	@sed -i "s/PIHOLEIP/$$PIHOLEIP/g" $$DATA/traefik/rules/pihole.yml

pihole-up:
	# update pihole
	pihole -up

pihole-upgrade: pihole-up pihole-port
	@echo "✅ Pi-hole upgrade done"

traefik: traefik-setup traefik-up
	@echo "✅ Traefik service running"

traefik-setup:
	@mkdir -p $$DATA/shared
	@mkdir -p $$DATA/traefik/
	# rules
	@cp -r rules $$DATA/traefik/
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

traefik-up:
	docker-compose -f traefik.yml --env-file=.env up -d
traefik-logs:
	docker-compose -f traefik.yml logs -f traefik
traefik-down:
	docker-compose -f traefik.yml down