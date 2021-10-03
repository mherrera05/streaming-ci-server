Drone CI server using Linode VM

---

## 📝 Table of Contents

- [📝 Table of Contents](#-table-of-contents)
- [🧐 About](#-about)
- [🏁 Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installing](#installing)
- [🔧 All in one run](#-all-in-one-run)
- [🎈 Usage](#-usage)
- [✍️ Authors](#️-authors)
- [🎉 Acknowledgements](#-acknowledgements)
- [🎉 Reference](#-reference)

## 🧐 About

Build your own continuos integration server with Drone using a Linode instance.

## 🏁 Getting Started

This project will allow you to get your own CI server.

### Prerequisites

What things you need to install the software and how to install them.

```
Linode Ubuntu Virtual Machine
Install Docker
Install NGINX
Domain
Run drone docker container
```

### Installing

To install Docker for Ubuntu machine just follow the instructions on https://docs.docker.com/engine/install/ubuntu/.

To check that you have docker installed.

```bash
> docker version
```

To install nginx just run the following command

```bash
> apt install nginx
```

After the installation process and for checking it is running. Run the command

```bash
> service nginx status
```

You will see the following output

```bash
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
     Active: active (running) since Sun 2021-10-03 20:37:00 UTC; 45s ago
       Docs: man:nginx(8)
   Main PID: 20790 (nginx)
      Tasks: 2 (limit: 1071)
     Memory: 5.2M
     CGroup: /system.slice/nginx.service
             ├─20790 nginx: master process /usr/sbin/nginx -g daemon on; master_process>
             └─20791 nginx: worker process

Oct 03 20:37:00 localhost systemd[1]: Starting A high performance web server and a reve>
Oct 03 20:37:00 localhost systemd[1]: Started A high performance web server and a rever>
```

* Once you have configured the domain to reach your machine and the OAuth app is registered on GitHub,we need to run the following command taken from drone CI documentation.
  
```bash
> docker run \
  --volume=/var/lib/drone:/data \
  --env=DRONE_GITHUB_CLIENT_ID={{DRONE_GITHUB_CLIENT_ID}} \
  --env=DRONE_GITHUB_CLIENT_SECRET={{DRONE_GITHUB_CLIENT_SECRET}} \
  --env=DRONE_RPC_SECRET={{DRONE_RPC_SECRET}} \
  --env=DRONE_SERVER_HOST={{DRONE_SERVER_HOST}} \
  --env=DRONE_SERVER_PROTO={{DRONE_SERVER_PROTO}} \
  --publish=8080:80 \ #avoid use the port taken for nginx
  --publish=444:443 \
  --restart=always \
  --detach=true \
  --name=drone \
  drone/drone:2
```

You should replace all variables values or load environment for them. The original 80 and 443 are taken by nginx service running in the machine.

* Once you have the server container running you should start the runner with following command.

```bash
> docker run -d \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e DRONE_RPC_PROTO=https \
  -e DRONE_RPC_HOST=drone.company.com \
  -e DRONE_RPC_SECRET=super-duper-secret \
  -e DRONE_RUNNER_CAPACITY=2 \
  -e DRONE_RUNNER_NAME=${HOSTNAME} \
  -p 3000:3000 \
  --restart always \
  --name runner \
  drone/drone-runner-docker:1
```

* After you have running drone server and drone runner containers we need to expose our running services using nginx and make them reachable through the DNS.

Create a file ```drone.conf``` in the following path

```bash
/etc/nginx/conf.d/
```

With the content to add new virtual host.

```bash
server {
       listen 80;
       listen 443;
       listen [::]:443;

       server_name <subdomain>;

       location / {
	       proxy_set_header    X-Real-IP           $remote_addr;
	       proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
	       proxy_set_header    X-Forwarded-Proto   $scheme;
	       proxy_set_header    Host                $host;
	       proxy_set_header    X-Forwarded-Host    $host;
	       proxy_set_header    X-Forwarded-Port    $server_port;
           proxy_pass 	   http://127.0.0.1:8080;

       }
}
```

Then to restart the nginx service just run the following command.

```bash
> service nginx restart
```

If all goes right and nginx restarts well you can request the domain on the web browser.


## 🔧 All in one run

To run the all in one installation add all the environment variables to your instance

```bash
export DRONE_GITHUB_CLIENT_ID=<github-client-id>
export DRONE_GITHUB_CLIENT_SECRET=<github-client-secret>
export DRONE_RPC_SECRET=<shared-secret>
export DRONE_SERVER_HOST=<domain-or-subdomain>
export DRONE_SERVER_PROTO=<protocol>
export HOSTNAME=<machine-name>
```

* Once you have loaded all the environment variables you just need to copy the all-in-one-run.sh file usgin scp command

```bash
> scp all-in-one-run.sh <user>@<ip>:<folder>
```

* Inside the machine, just run the instruction

```bash
> ./all-in-one-run.sh
```

## 🎈 Usage

You have to enable the repository that you want to integrate with drone and add the .drone.yml file.

## ✍️ Authors

- [Miguel Herrera](https://github.com/mherrera05) - Full Stack Developer

## 🎉 Acknowledgements

## 🎉 Reference
- [Drone](https://www.drone.io)
- [Linode](https://cloud.linode.com)
