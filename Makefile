docker-install:
	# install docker
	curl -fsSL https://get.docker.com -o get-docker.sh
	sudo sh get-docker.sh

	sudo usermod -aG docker pi

	# install docker-compose from python3-pip
	sudo apt install -y libffi-dev libssl-dev python3 python3-pip
	sudo pip3 install docker-compose