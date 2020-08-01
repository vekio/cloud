include .env
export

docker-install:
	# install docker
	curl -fsSL https://get.docker.com -o get-docker.sh
	sudo sh get-docker.sh
	sudo usermod -aG docker pi
	# install docker-compose from python3-pip
	sudo apt install -y libffi-dev libssl-dev python3 python3-pip
	sudo pip3 install docker-compose

pihole-install:
	# pihole install
	curl -sSL https://install.pi-hole.net | bash
	# unbound install
	sudo apt install unbound
	wget -O root.hints https://www.internic.net/domain/named.root
	sudo mv root.hints /var/lib/unbound/
	sudo cp pi-hole.conf /etc/unbound/unbound.conf.d/pi-hole.conf

setup:
	mkdir -P $$DATA/shared
	# acme	
	mkdir -p $$DATA/traefik/acme
	touch $$DATA/traefik/acme/acme.json
	chmod 600 $$DATA/traefik/acme/acme.json
	# logs
	touch $$DATA/traefik/traefik.log
	# network
	docker network create proxy
	# basic-auth (htpasswd)
	sudo apt install -y apache2-utils
	echo $(htpasswd -nb $$AUTH-USER $$AUTH-PASSWORD) | sed -e s/\\$/\\$\\$/g > $$DATA/shared/.htpasswd
	

traefik-up:
	docker-compose -f traefik.yml --env-file=.env up -d
traefik-logs:
	docker-compose -f traefik.yml logs -f traefik
traefik-down:
	docker-compose -f traefik.yml down