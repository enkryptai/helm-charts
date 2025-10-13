

# EnkryptAI Lite Installation Guide

This guide walks you through installing **EnkryptAI Lite** using Helm and applying necessary CRDs.

---

## Prerequisites

- Kubernetes cluster (v1.20+ recommended)
- Helm 3 installed
- `kubectl` configured to access your cluster
- This chart requires you to have Kubernetes secret for keys/bucket. Kindly check ../../test-enkrytai-lite-secret.yaml for example

---

## Step 1: Add Helm Repository

Add the Helm repository (replace `<repo_name>` and `<repo_url>` with the actual values):

```bash
helm repo add enkryptai https://enkryptai.github.io/helm-charts/
helm repo update
helm search repo enkryptai
kubectl create ns enkryptai-stack
````

---

## Step 2: Apply Custom Resource Definitions (CRDs) (Optional)

Before installing EnkryptAI Lite, apply the required CRDs:

```bash
kubectl apply -f crds/
```

---

## Step 3: Install or Upgrade EnkryptAI Lite

Install or upgrade the Helm release:

**NOTE: Kindly use the latest release. Before apply ensure below secrets are present** 
1. Name: `s3-cred` in Namespace: `enkryptai-stack`
2. Name: `guardrails-env-secret` in Namespace: `enkryptai-stack`
3. Name: `redteam-proxy-env-secret` in Namespace: `enkryptai-stack` and `redteam-jobs`

Kindly update values file before applying

```bash
helm upgrade --install enkryptai-lite enkryptai/enkryptai-lite -n enkryptai-stack  --debug -f values.yaml
```

* `enkryptai-lite`: Name of the Helm release
* `enkryptai-stack`: Namespace to deploy the release
* `.`: Path to the Helm chart (current directory)
* `--debug`: Enables debug output for troubleshooting

---

## Step 4: Verify Installation

Check that all pods and resources are running:

```bash
kubectl get all -n enkryptai-stack
```

---

## Notes

* Ensure the namespace `enkryptai-stack` exists or create it:

```bash
kubectl create namespace enkryptai-stack
```

* Applying CRDs first is required; otherwise, the Helm chart may fail to install.


