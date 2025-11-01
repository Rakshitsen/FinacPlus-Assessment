# FinacPlus Assessment — CI/CD Pipeline Project

## 🚀 Overview

This project implements a **complete DevSecOps CI/CD pipeline** using Jenkins, Docker, and Kubernetes.  
It automates the full software delivery lifecycle — from code build to secure deployment — following real-world SRE and DevOps practices.

---

## 🧩 Tech Stack

| Component | Purpose |
|-----------|---------|
| **Jenkins** | CI/CD orchestrator (Scripted Pipeline) |
| **Docker** | Build immutable container images |
| **Docker Hub** | Central registry for image storage |
| **Kubernetes (Kind)** | Deployment and runtime environment |
| **Trivy** | Container image vulnerability scanning |
| **Prometheus + Grafana** | Application metrics and monitoring |
| **Flask (Python)** | Sample application for demonstration |

---

## ⚙️ Pipeline Flow

```
Git → Jenkins → Docker Hub → Kubernetes (dev → stage → prod)
```

### Stage Summary

| Stage | Description |
|-------|-------------|
| **1. Checkout Source** | Pull latest code from GitHub |
| **2. Build & Test** | Validate Python and Docker setup |
| **3. Build Docker Image** | Build versioned, immutable image |
| **4. Security Scan (Trivy)** | Scan image for CVEs; archive JSON report |
| **5. Push to Registry** | Push image to Docker Hub with both tag and `latest` |
| **6. Deploy to Kubernetes** | Auto-create namespace if missing; update or create deployment |
| **7. Verify Deployment** | Port-forward + `/health` check; kill background process safely |
| **8. Manual Promotion Gates** | Require approval before deploying to Stage and Prod |
| **9. Post-Build Cleanup** | Remove temporary images and workspace |
| **10. Audit Summary** | Print deployment details; optional email notification |

---

## 🛡️ Security & Compliance

- **Trivy Scan:** Detects vulnerabilities in Docker images before pushing.
- **RBAC-ready:** Jenkins uses Kubernetes credentials via Jenkins Credentials Manager.
- **Immutable Images:** Each build produces a unique, traceable image tag.
- **Rollback Support:** Deploy any previous image tag safely.

---

## 📈 Monitoring & Observability

- Integrated **Prometheus metrics exporter** in Flask app (`/metrics` endpoint).
- **Grafana dashboards** display request count, latency, and health.
- Liveness and readiness probes ensure self-healing pods.

---

## 🔄 Promotion Flow

| Environment | Trigger | Description |
|-------------|---------|-------------|
| **Dev** | Automatic on push | Build → Scan → Deploy |
| **Stage** | Manual approval | Promotion from tested Dev image |
| **Prod** | Manual approval (30 min window) | Final promotion of verified image |

---

## 🧰 How to Run Locally

### 1. Pre-requisites

- Docker  
- Kubernetes cluster (e.g., Kind or Minikube)  
- Jenkins (with Docker + Kubectl + Git installed)

### 2. Clone repository

```bash
git clone https://github.com/Rakshitsen/FinacPlus-Assessment.git
```

### 3. Set credentials in Jenkins

- `Docker_cred` → Docker Hub username/password
- `Git_cred` → GitHub access token
- `KUBECONFIG_FILE` → Kubeconfig secret file

### 4. Run job

- Create a *Multibranch Pipeline Job* in Jenkins.
- Point to this repository.
- Build → approve promotions.

---

## 📄 Artifacts & Reports

- **Trivy Reports:** `trivy-report-<build>.json`
- **Deployment Info:** `deploy-info-<build>.txt`
- **Jenkins Logs:** Include rollout status, health, and image digest.

---

## 🧠 Key Learnings

- Build once → promote immutably → verify → rollback if needed.
- CI/CD pipelines must be secure, observable, and self-healing.
- Manual approvals and metrics visibility make the pipeline production-ready.

---

## 👤 Author

**Rakshit Sen**