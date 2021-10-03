#!/bin/bash

set -e

echo "> Refreshing Ubuntu Repositories.."
apt update

echo "> Installing dependencies for Docker.."
apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release -y

echo "> Add docker GPC.."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "> Register Docker repository.."
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "> Refreshing repositories.."
apt update

echo "> Installing Docker.."
apt-get install docker-ce docker-ce-cli containerd.io -y

echo "> Checking Docker CLI is already installed.."
docker version

echo "> Installing NGINX.."
apt install NGINX

echo "> Checking NGINX version.."
nginx -v

echo "> Running Drone Server container.."
docker run \
  --volume=/var/lib/drone:/data \
  --env=DRONE_GITHUB_CLIENT_ID=${DRONE_GITHUB_CLIENT_ID} \
  --env=DRONE_GITHUB_CLIENT_SECRET=${DRONE_GITHUB_CLIENT_SECRET} \
  --env=DRONE_RPC_SECRET=${DRONE_RPC_SECRET} \
  --env=DRONE_SERVER_HOST=${DRONE_SERVER_HOST} \
  --env=DRONE_SERVER_PROTO=${DRONE_SERVER_PROTO} \
  --publish=8080:80 \
  --publish=444:443 \
  --restart=always \
  --detach=true \
  --name=drone \
  drone/drone:2

echo "> Running Drone Runner container.."
docker run -d \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e DRONE_RPC_PROTO=${DRONE_SERVER_PROTO} \
  -e DRONE_RPC_HOST=${DRONE_SERVER_HOST} \
  -e DRONE_RPC_SECRET=${DRONE_RPC_SECRET} \
  -e DRONE_RUNNER_CAPACITY=1 \
  -e DRONE_RUNNER_NAME=${HOSTNAME} \
  -p 3000:3000 \
  --restart always \
  --name runner \
  drone/drone-runner-docker:1

echo "> Add new virtual host for nginx.."
echo \
    "server {
       listen 80;
       listen 443;
       listen [::]:443;

       server_name $DRONE_SERVER_HOST;

       location / {
	       proxy_set_header    X-Real-IP           \$remote_addr;
	       proxy_set_header    X-Forwarded-For     \$proxy_add_x_forwarded_for;
	       proxy_set_header    X-Forwarded-Proto   \$scheme;
	       proxy_set_header    Host                \$host;
	       proxy_set_header    X-Forwarded-Host    \$host;
	       proxy_set_header    X-Forwarded-Port    \$server_port;
           proxy_pass 	   http://127.0.0.1:8080;

       }
}" > /etc/nginx/conf.d/drone.conf

echo "> Restarting NGINX service.."
service nginx restart
