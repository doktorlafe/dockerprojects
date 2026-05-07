# 23 - Kubernetes Setup

Kubernetes manifesty pro deployment aplikace.

## Spuštění (vyžaduje k8s cluster)

```bash
cd 23-kubernetes-setup
kubectl apply -f deployment.yaml
kubectl get deployments -n myapp
kubectl get services -n myapp
```

## Odebrání

```bash
kubectl delete namespace myapp
```
