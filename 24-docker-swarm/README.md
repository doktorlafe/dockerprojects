# 24 - Docker Swarm

Docker Swarm orchestrace.

## Inicializace Swarm

```bash
docker swarm init
```

## Deployment

```bash
cd 24-docker-swarm
docker stack deploy -c docker-compose.yml mystack
docker service ls
docker service scale mystack_web=5
```

## Odebrání

```bash
docker stack rm mystack
```
