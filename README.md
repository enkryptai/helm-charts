#  EnkryptAI Helm Charts

This repository contains Helm charts for deploying the **EnkryptAI stack** — including the core platform and supporting services — on AWS using **CloudFormation** and **Amazon EKS**.

---

# **EnkryptAI Stack Deployment Prerequisites**
This document outlines the infrastructure and configuration requirements for deploying the **EnkryptAI stack** on an existing Kubernetes cluster.
---

## 1. GPU Node Group (Guardrails)

The **Guardrails** component requires GPU-enabled nodes. Create a dedicated GPU node group using the following configuration.

**Node Group Name:** `gpu-node-group`

| **Configuration**         | **Value**                          |
| ------------------------- | ---------------------------------- |
| **Instance Type**         | `p3.2xlarge`                       |
| **Capacity Type**         | `ON_DEMAND`                        |
| **AMI Type**              | `AL2023_x86_64_NVIDIA`             |
| **Disk Size**             | `100 GB (gp3)`                     |
| **Scaling Configuration** | Desired: `2` • Min: `1` • Max: `2` |

**Usage Note:**
The **Guardrails pod** requires a GPU and will be **scheduled exclusively** on this node group.

---

## 2. Redteaming Node Group

The **Redteaming** workloads run on a separate node group optimized for compute-intensive tasks.

**Node Group Name:** `redteaming-node-group`

| **Configuration**         | **Value**                           |
| ------------------------- | ----------------------------------- |
| **Instance Type**         | `r7i.xlarge`                        |
| **Capacity Type**         | `ON_DEMAND`                         |
| **AMI Type**              | `AL2_x86_64`                        |
| **Disk Size**             | `100 GB (gp3)`                      |
| **Scaling Configuration** | Desired: `2` • Min: `2` • Max: `10` |
| **Labels**                | `dedicated: redteaming`             |
| **Taints**                | `app=redteaming:NoSchedule`         |

**Usage Note:**
This node group ensures **Redteaming jobs** are scheduled exclusively on dedicated infrastructure.

---

## 3. Prerequisite Namespaces and Secrets

Before installing the Helm chart, make sure the following namespaces and secrets are created.
(EnkryptAI will provide the Helm chart and secret values.)

### **Namespaces**

```sh
enkryptai-stack
redteam-jobs
```

---

### **Secrets**

| **Namespace**   | **Secret Name**              |
| --------------- | ---------------------------- |
| enkryptai-stack | elastic-env-secret           |
| enkryptai-stack | frontend-env-secret          |
| enkryptai-stack | gateway-env-secret           |
| enkryptai-stack | gateway-migration-env-secret |
| enkryptai-stack | guardrails-env-secret        |
| enkryptai-stack | onprem                       |
| enkryptai-stack | openfga-env-secret           |
| enkryptai-stack | opensearch-cred              |
| enkryptai-stack | opensearch-securityconfig    |
| enkryptai-stack | postgres-superuser-secret    |
| enkryptai-stack | redteam-proxy-env-secret     |
| enkryptai-stack | s3-cred                      |
| enkryptai-stack | superuser-secret             |
| redteam-jobs    | redteam-proxy-env-secret     |

---

## 4. Secret Usage Overview

The following table summarizes which applications use each secret.

### **Application Groups**

* **Internal Applications:** `gateway-kong`, `frontend`, `redteaming`, `guardrails`
* **On-Premise Applications:** `opensearch`, `openfga`, `cnpg`

| **Secret Name**                | **Used By**                                                          |
| ------------------------------ | -------------------------------------------------------------------- |
| `elastic-env-secret`           | `gateway-kong`, `opensearch`                                         |
| `frontend-env-secret`          | `frontend`                                                           |
| `gateway-env-secret`           | `gateway-kong`                                                       |
| `gateway-migration-env-secret` | `gateway-kong`                                                       |
| `guardrails-env-secret`        | `guardrails`                                                         |
| `onprem`                       | Supabase (on-prem database and related services)                     |
| `openfga-env-secret`           | `openfga`                                                            |
| `opensearch-cred`              | `opensearch`                                                         |
| `opensearch-securityconfig`    | `opensearch`                                                         |
| `postgres-superuser-secret`    | Supabase on-prem                                                     |
| `redteam-proxy-env-secret`     | `redteaming`, `redteam-jobs`                                         |
| `s3-cred`                      | `redteaming`, Supabase (on-prem MinIO for internal artifact storage) |
| `superuser-secret`             | Postgres CNPG credentials                                            |

---

## Summary

Before deploying the Helm chart:

1. **Create GPU and Redteaming node groups** with the configurations listed above.
2. **Create namespaces:** `enkryptai-stack`, `redteam-jobs`.
3. **Apply all required secrets** (values will be provided by EnkryptAI).
4. Proceed with the **Helm chart installation** once these prerequisites are met.

---

## Available Helm Charts


| Chart                                                   | Description                                                                  |
| ------------------------------------------------------- | ---------------------------------------------------------------------------- |
| [`enkryptai-stack`](./charts/enkryptai-stack/README.md) | Full-stack deployment including all EnkryptAI services                       |
| [`platform`](./charts/platform/README.md)               | Core platform dependencies and shared infrastructure                         |
| [`enkryptai-lite`](./charts/enkryptai-lite/README.md)   | Lightweight deployment — includes Red Teaming and Guardrails components only |

---

## Support

If you face any issues during deployment, reach out to the **EnkryptAI DevOps Team** or raise a GitHub issue in this repository.

---
