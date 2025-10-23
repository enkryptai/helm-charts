# Container Image Reference — EnkryptAI Platform and EnkryptAI Stack

This document lists all container images and their corresponding tags used within the **EnkryptAI Production Deployment**.

**Note:** Image tags are subject to change in future releases depending on version updates.

---

## 1. Registry Access Requirements

Before deploying EnkryptAI components, ensure that your **EKS cluster nodes** have network access and pull permissions for the following container registries.  
These registries must be whitelisted in outbound firewall rules, proxy configurations, or VPC egress settings.  
If applicable, update IAM roles to allow image pulls from the required sources.

| Registry | Description | Access Type | Notes |
|-----------|--------------|--------------|-------|
| `188451452903.dkr.ecr.us-east-1.amazonaws.com` | EnkryptAI Private ECR | Private | Requires AWS IAM role or ECR pull permissions. |
| `amazonaws.com` | AWS Official Images | Public | Used for AWS CLI and other AWS-maintained images. |
| `docker.io` | Docker Hub | Public | Ensure rate limits are handled; use Docker Hub credentials if required. |
| `gcr.io` | Google Container Registry | Public | Used for Kubernetes utility images. |
| `ghcr.io` | GitHub Container Registry | Public | Used for CloudNativePG and PostgreSQL images. |
| `quay.io` | Red Hat / CNCF Registry | Public | Used for Argo, MinIO, and related components. |
| `nvcr.io` | NVIDIA NGC Registry | Restricted | Requires NVIDIA API key or authentication for GPU-related components. |
| `registry.k8s.io` | Kubernetes Official Registry | Public | Used for Ingress Controller, Node Feature Discovery, and similar components. |

---

## 2. Amazon ECR (Private Registry)

| Component | Image Repository | Tag |
|------------|------------------|-----|
| Frontend | `188451452903.dkr.ecr.us-east-1.amazonaws.com/enkryptai-prod/frontend` | `dd3c7e3` |
| Gateway | `188451452903.dkr.ecr.us-east-1.amazonaws.com/enkryptai-prod/gateway` | `2710bcb` |
| Gateway Sync | `188451452903.dkr.ecr.us-east-1.amazonaws.com/enkryptai-prod/gateway-sync` | `2710bcb` |
| Guardrails | `188451452903.dkr.ecr.us-east-1.amazonaws.com/enkryptai-prod/guardrails` | `aa2fdfb` |
| Redteam Proxy | `188451452903.dkr.ecr.us-east-1.amazonaws.com/enkryptai-prod/redteam-proxy` | `8cd384f` |
| Supabase | `188451452903.dkr.ecr.us-east-1.amazonaws.com/supabase` | `16.0.1` |

---

## 3. AWS Official Images

| Component | Image Repository | Tag |
|------------|------------------|-----|
| AWS CLI | `amazon/aws-cli` | `2.17.18`, `2.27.55` |

---

## 4. Docker Hub (Public Registry)

| Component | Image Repository | Tag |
|------------|------------------|-----|
| BusyBox | `docker.io/busybox` | `latest` |
| OpenSearch | `docker.io/opensearchproject/opensearch` | `3.2.0` |
| OpenSearch Dashboards | `docker.io/opensearchproject/opensearch-dashboards` | `3.2.0` |
| KeyDB | `eqalpha/keydb` | `x86_64_v6.3.2` |
| Fluent Bit | `fluent/fluent-bit` | `3.2.1` |
| Kong | `kong` | `2.8.1` |
| MinIO | `minio/minio` | `latest` |
| MinIO Client | `minio/mc` | `-` |
| NATS | `nats` | `2.10.10`, `2.11.8-alpine` |
| PostgreSQL | `postgres` | `15`, `15-alpine`, `16` |
| PostgREST | `postgrest/postgrest` | `v12.2.8` |
| Nginx | `nginx` | `alpine` |

---

## 5. Google Container Registry (GCR)

| Component | Image Repository | Tag |
|------------|------------------|-----|
| Kube RBAC Proxy | `gcr.io/kubebuilder/kube-rbac-proxy` | `v0.15.0` |

---

## 6. GitHub Container Registry (GHCR)

| Component | Image Repository | Tag |
|------------|------------------|-----|
| CloudNativePG Operator | `ghcr.io/cloudnative-pg/cloudnative-pg` | `1.27.0` |
| CloudNativePG PostgreSQL | `ghcr.io/cloudnative-pg/postgresql` | `17.4-8` |

---

## 7. Quay.io Registry

| Component | Image Repository | Tag |
|------------|------------------|-----|
| Argo CLI | `quay.io/argoproj/argocli` | `v3.7.1` |
| Argo Events | `quay.io/argoproj/argo-events` | `v1.9.7` |
| Argo Workflow Controller | `quay.io/argoproj/workflow-controller` | `v3.7.1` |
| MinIO (Pinned) | `quay.io/minio/minio` | `RELEASE.2022-11-17T23-20-09Z` |
| Go HTTPBin | `quay.io/holos/mccutchen/go-httpbin` | `v2.14.1` |

---

## 8. NVIDIA NGC (NVIDIA Container Registry)

| Component | Image Repository | Tag |
|------------|------------------|-----|
| GPU Operator Validator | `nvcr.io/nvidia/cloud-native/gpu-operator-validator` | `v24.9.0` |
| GPU Operator | `nvcr.io/nvidia/gpu-operator` | `v24.9.0` |
| Container Toolkit | `nvcr.io/nvidia/k8s/container-toolkit` | `v1.13.1-ubi8` |
| DCGM Exporter | `nvcr.io/nvidia/k8s/dcgm-exporter` | `3.3.8-3.6.0-ubuntu22.04` |
| Device Plugin | `nvcr.io/nvidia/k8s-device-plugin` | `v0.17.0-ubi9` |

---

## 9. NATS.io Images

| Component | Image Repository | Tag |
|------------|------------------|-----|
| Jetstream Controller | `natsio/jetstream-controller` | `0.19.1` |
| NATS Box | `natsio/nats-box` | `0.18.0` |
| Config Reloader | `natsio/nats-server-config-reloader` | `0.14.0`, `0.19.1` |
| Prometheus Exporter | `natsio/prometheus-nats-exporter` | `0.14.0`, `0.17.3` |

---

## 10. OpenFGA / OpenSearch Operator

| Component | Image Repository | Tag |
|------------|------------------|-----|
| OpenFGA | `openfga/openfga` | `v1.8.9` |
| OpenSearch Operator | `opensearchproject/opensearch-operator` | `2.8.0` |

---

## 11. Kubernetes Official Registry

| Component | Image Repository | Tag |
|------------|------------------|-----|
| NGINX Ingress Controller | `registry.k8s.io/ingress-nginx/controller` | `v1.13.3` |
| Node Feature Discovery | `registry.k8s.io/nfd/node-feature-discovery` | `v0.16.6` |

---

## 12. Supabase Images

| Component | Image Repository | Tag |
|------------|------------------|-----|
| GoTrue (Auth) | `supabase/gotrue` | `v2.169.0` |
| Postgres Meta | `supabase/postgres-meta` | `v0.86.0` |
| Storage API | `supabase/storage-api` | `v1.19.1` |
| Studio | `supabase/studio` | `20240326-5e5586d` |

---

## 13. Utility Tools

| Component | Image Repository | Tag |
|------------|------------------|-----|
| Kubernetes Wait Utility | `groundnuty/k8s-wait-for` | `v2.0` |


