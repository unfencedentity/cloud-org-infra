# k8s-playground

Minimal Kubernetes playground to learn core concepts hands-on.
Goal: build intuition through small, repeatable experiments.

## Scope
Included:
- Pod
- Deployment
- Service (ClusterIP)
- Manual scaling

Not included (for now):
- Ingress
- Helm
- Secrets/ConfigMaps
- Production hardening

## Prereqs
- kubectl installed
- A local cluster (Docker Desktop Kubernetes OR k3s OR minikube)

## Run order
1) 01-pod
2) 02-deployment
3) 03-service
4) 04-scaling
