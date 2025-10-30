# Simple Flask App (Jenkins CI/CD Project)

A minimal Flask web service to demonstrate CI/CD automation with Jenkins, Docker, and Kubernetes.

## Run Locally

```bash
python3 app.py
# visit http://localhost:5000
# health check: http://localhost:5000/health
```

## Container Build

```bash
docker build -t simple-app:latest .
docker run -p 5000:5000 simple-app:latest
```

## Kubernetes Deploy

```bash
kubectl apply -f k8s/deployment.yaml
kubectl get pods,svc
```

## Health Endpoint

`/health` → returns `{"status": "ok"}` with HTTP 200.

## Version

v0.1.0 – Base tested release before Jenkins pipeline integration.