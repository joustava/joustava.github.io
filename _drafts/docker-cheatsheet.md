---
title: Docker Cheatsheet
---

As I'm not using Docker every office hour, I tend to forget some basics once in a while. Here is a list of commands that come in handy with a few background notes.

### Docker Client basics

- `docker create <image_name>` creates a docker container from image with name image_name.
- `docker start <image_id>` (re)start a docker container wfrom image_id.
- `docker start -a <image_id>` start a docker container from image_id and attach to it.
- `docker run <image_id>` create and start container.
- `docker ps -all` show all existing containers on system.
- `docker system prune` remove all containers, networks, images, build cache.
- `docker logs <container_id>` show logs of runnig container.
- `docker stop <container_id>` try to stop container gracefully.
- `docker kill <container_id>` stop container immediately no matter what.
- `docker exec -it <container_id> <command>` run additional command after container started.
- `docker exec -it <container_id> sh` run shell command after container started.
- Ctrl-D or ctrl-C or  'exit' to leave container shell.

### Creating Docker images

- `docker build .` create a docker image from a Dockerfile in current directory.
- `docker build -t <docker_user_id>/<project_name>:<version_tag> .`

These build commans depend on a Dockerfile being available with build instructions. This file typically has the following format.

```docker
FROM image

WORKDIR /usr/app
COPY . .
RUN script

CMD cmd
```

### Running multiple services

- `docker-compose up` run those containers defined in a docker-compose.yml
- `docker-compose up --build`  rebuild and run the containers defined in docker-compose.yml
- `docker-compose down` stop and remove containers defined in docker-compose.yml
- `docker-compose ps` status of containers defined in docker-compose.yml

 ```yaml
version: '3'

# These services can refer to each other by service name as
# a dedicated network will be setup for this 'docker services context'.
services:
	service-1:
		image: db # e.g some docker image from docker hub used for storage
	service-2:
		build: ./ # build from dockerfile in current dir.
    ports: 
    	- "4000:8000" # bind service port (8000) to host port (4000)
 ```

### Volumes



### Kubernetes `kubectl`

- `kubectl apply -f <file-name>.yaml ` apply a config file to the kubernetes master

- `kubectl apply -f <folder> ` apply all config found in folder

- `kubectl get <Kind>` show basic status list of object types

- `kubectl get <Kind> -o wide` show extended status list of obect types

- `kubectl describe <Kinds>` show elaborate configuration of all Kinds

- `kubectl describe <Kind> <object name>` show elaborate configuration a Kind of object with name

- `kubectl delete -f <file-name>.yaml` delete configuration from kubernetes master

- `kubectl set image deployment/client-deployment client=joustava/multi-client:1.0.0`

   Imperative update when updating.
   
- `kubectl create secret <type> <name> --from-literal key=value`

- 

### Skaffold

