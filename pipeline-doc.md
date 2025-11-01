# FinacPlus Assessment – Detailed CI/CD Pipeline Documentation

## 🧭 1. Objective
Design and implement a **complete DevSecOps CI/CD pipeline** using Jenkins, Docker, and Kubernetes.  
Goal: automate build → scan → deploy → verify → promote → rollback, with security and observability built in.

---

## 🧩 2. Architecture Overview

```
Developer Commit (GitHub)
│
▼
Jenkins Multibranch Pipeline
│
┌─────────────────────────────┐
│ 1. Build & Test             │
│ 2. Security Scan (Trivy)    │
│ 3. Push to Docker Hub       │
│ 4. Deploy to Kubernetes     │
│ 5. Verify Health            │
│ 6. Approve & Promote        │
│ 7. Audit & Notify           │
└─────────────────────────────┘
│
▼
Kubernetes Namespaces
(dev → stage → prod)
```

**Tools involved**

| Tool | Purpose |
|------|----------|
| Jenkins | CI/CD automation |
| Docker | Build immutable containers |
| Docker Hub | Artifact registry |
| Kubernetes (Kind) | Deployment environment |
| Trivy | Vulnerability scanning |
| Prometheus + Grafana | Monitoring and metrics |
| Flask | Demo application |

---

## ⚙️ 3. Jenkins Pipeline Logic (Scripted)

### Stage 1 – Checkout Source
Pull latest code from GitHub (`checkout scm`).  
Ensures every build starts from a clean, versioned commit.

---

### Stage 2 – Build & Test
Runs quick validation:
```bash
python3 --version
docker --version
```

Confirms environment readiness.

---

### Stage 3 – Build Docker Image

```bash
docker build -t ${IMAGE_REPO}:${TAG} .
docker tag ${IMAGE_REPO}:${TAG} ${IMAGE_REPO}:latest
```

Each image gets a **unique tag** (`BUILD_NUMBER`) for traceability.
Using build-time tagging implements **immutable artifacts**.

---

### Stage 4 – Security Scan (Trivy)

Runs vulnerability analysis on the local image before pushing.

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(pwd):/output aquasec/trivy:latest image \
  --format json --output /output/trivy-report-${BUILD_NUMBER}.json ${IMAGE_REPO}:${TAG}
```

**Why important:** prevents shipping known CVEs; report is archived as evidence.
The `|| true` keeps pipeline informative (non-blocking mode).

---

### Stage 5 – Push Image to Docker Hub

```groovy
withCredentials([usernamePassword(...)]) {
  withEnv(["DOCKER_CONFIG=${env.WORKSPACE}/.docker-tmp"]) {
      sh 'printf "%s" "$PASS" | docker login -u "$USER" --password-stdin'
      sh 'docker push ${IMAGE_REPO}:${TAG}'
  }
}
```

#### Key learnings

* `printf "%s"` ensures password is sent **exactly** as it is (no newline).
* `withEnv` exposes Groovy variables to shell safely.
* `set -euo pipefail` makes the shell **fail-fast** (no silent errors).
* Backslash `\$USER` prevents Groovy from eating the `$` meant for Bash.

The block creates a temporary Docker config so credentials aren't stored unencrypted under `/var/lib/jenkins/.docker/`.

---

### Stage 6 – Deploy to Kubernetes

Handles both first-time deploys and updates.

```bash
# Ensure namespace exists
kubectl get ns ${TARGET_NS} >/dev/null 2>&1 || \
kubectl create ns ${TARGET_NS}

# Update or create deployment
if kubectl get deploy simple-app -n ${TARGET_NS} >/dev/null 2>&1; then
  kubectl set image deploy/simple-app simple-app=${IMAGE_REPO}:${TAG} -n ${TARGET_NS}
else
  kubectl apply -f k8s/deployment.yml -n ${TARGET_NS}
  kubectl set image deploy/simple-app simple-app=${IMAGE_REPO}:${TAG} -n ${TARGET_NS}
fi
```

#### How it works

* `>/dev/null 2>&1` hides command output; only exit code decides logic.
* Exit 0 → deployment exists → update image.
* Exit 1 → no deployment → create new one.

This keeps Jenkins logs clean and automation idempotent.

---

### Stage 7 – Verify Deployment

```bash
kubectl port-forward svc/simple-app-service 7070:80 -n ${TARGET_NS} &
PF_PID=$!
sleep 5
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:7070/health)
kill $PF_PID || true
```

* Runs health probe on `/health`.
* Captures the port-forward PID and kills it to avoid zombie processes.
* Build fails if HTTP 200 not returned.

---

### Stage 8 – Manual Promotion Gates

Two approval points:

| From | To | Timeout | Purpose |
|------|-----|---------|---------|
| Dev | Stage | 10 min | human review before promotion |
| Stage | Prod | 30 min | controlled production rollout |

Each gate pauses pipeline until approved via Jenkins UI.
Uses `input` step and re-invokes the same job with new parameters.

---

### Stage 9 – Post-Build Cleanup

```bash
docker rmi ${IMAGE_REPO}:${TAG} || true
cleanWs()
```

Keeps agents lightweight and prevents storage leaks.

---

### Stage 10 – Audit & Notification

`finally` block always executes:

* Prints deployment summary (env, namespace, tag, status).
* Optionally emails results (via `emailext`).
* Verifies running image digest from cluster for audit trail.

---

## 🛡️ 4. Security & Best-Practice Notes

| Concept | Why it matters |
|---------|----------------|
| **Immutable images** | Guarantees reproducibility. Tags are mutable; digests (`sha256`) are not. |
| **withCredentials** | Injects secrets safely; no hard-coded passwords. |
| **withEnv** | Exposes Groovy vars (`IMAGE_REPO`, `TAG`) to shell scope. |
| **set -euo pipefail** | Stops build on undefined variables or command failure. |
| **/dev/null 2>&1** | Suppresses noisy output; relies on exit status only. |
| **Namespace check** | `kubectl get ns \|\| create ns` makes deploy idempotent. |
| **Rollback parameter** | Enables re-deploying a previous tag without rebuild. |

---

## 📈 5. Monitoring Integration (Phase 6C)

Flask app exposes Prometheus metrics via:

```python
from prometheus_flask_exporter import PrometheusMetrics
metrics = PrometheusMetrics(app)
```

Prometheus scrapes `/metrics`, and Grafana visualizes request counts, latency, and error rates.
Readiness and liveness probes use `/health` for auto-healing.

---

## 🔁 6. Promotion & Rollback Flow

| Scenario | Action |
|----------|--------|
| **Normal Dev build** | Build → Scan → Push → Deploy → Health check |
| **Stage promotion** | Manual approval; reuses same image tag |
| **Prod promotion** | 30-min approval window |
| **Rollback** | Run job with `ROLLBACK=true` and previous `IMAGE_TAG` |

No rebuild happens during promotions or rollback — exact image reused.

---

## 🧠 7. Personal Learning Notes

* `printf "%s"` avoids extra newline — best for non-interactive logins.
* Backslash (`\`) before `$` keeps Groovy from expanding shell vars too early.
* `withEnv([...])` temporarily adds environment variables inside its scope.
* `>/dev/null 2>&1` = discard both stdout & stderr → rely solely on exit code.
* Exit 0 = success; non-zero = failure → drives conditional automation.
* Tags can change; **digests cannot** — always prefer digests for production.
* Promotion = reuse a verified artifact, *never rebuild it*.
* Syntax difference: scripted pipelines handle notifications in `finally`, not declarative `post`.
* `cat > deploy-info.txt` captures the exact digest (`RepoDigests[0]`) for traceability.

---

## 🧩 8. Future Enhancements

* Add **branch-based namespace** logic for feature environments.
* Use **namespace-scoped ServiceAccounts (RBAC)** instead of full kubeconfig.
* Enforce **Trivy exit-code 1** for critical vulnerabilities.
* Integrate **Slack notifications** and **alerting rules** in Prometheus.
* Move to **GitOps (Argo CD)** once pipeline stabilizes.

---

## ✅ 9. Outcome

You now have a fully functional **secure, observable, and auditable CI/CD pipeline**:

* End-to-end automation (build → deploy → verify)
* Integrated security scanning
* Approval-based promotions
* Real-time monitoring and self-healing
* Clear audit and rollback capability

A solid foundation for any SRE or DevOps role.

---

*Documented by Rakshit Sen – learning notes and implementation summary, 2025.*