

# EnkryptAI Lite Installation Guide

This guide walks you through installing **EnkryptAI Lite** using Helm and applying necessary CRDs.

---

## Prerequisites

- Kubernetes cluster (v1.20+ recommended)
- Helm 3 installed
- `kubectl` configured to access your cluster

---

## Step 1: Add Helm Repository

Add the Helm repository (replace `<repo_name>` and `<repo_url>` with the actual values):

```bash
helm repo add <repo_name> <repo_url>
helm repo update
````

---

## Step 2: Apply Custom Resource Definitions (CRDs)

Before installing EnkryptAI Lite, apply the required CRDs:

```bash
kubectl apply -f crds/
```

---

## Step 3: Install or Upgrade EnkryptAI Lite

Install or upgrade the Helm release:

```bash
helm upgrade --install enkryptai-lite -n enkryptai-stack . --debug
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


