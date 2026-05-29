# Preparing the Override Values File

Before installation, create a custom override values file based on your environment and deployment requirements.

A base override values file is provided as part of the release package. Customers should copy and modify this file instead of editing the default chart values directly.

Example:

```bash
cp override-values.yaml customer-override-values.yaml
```

The final installation should always reference the customized override file.

---

# Required Configuration Changes

The following values must be reviewed and updated before deployment.

---

## Configure Container Registry

Update the registry configuration to match the registry being used in your environment.

Example:

```yaml
    registry: <your-registry>
```

If using a private registry, ensure:

* image pull secrets are configured correctly
* cluster nodes have registry access
* the registry is reachable from the cluster

---

## Configure Domain

Update the base domain used by ingress resources and application endpoints.

Example:

```yaml
enkryptai:
  global:
    domain: example.company.com
```

---

# External Secrets Configuration

External secrets are disabled by default.

Enable this feature only if your environment uses:

* Azure Key Vault
* AWS Secrets Manager

Example:

```yaml
enkryptai:
  global:
    externalSecrets:
      enabled: true
```

---

## Azure Key Vault Configuration

For Azure environments:

```yaml
enkryptai:
  global:
    externalSecrets:
      clusterSecretStore:
        enabled: true
        provider: azure
```

Additional Azure workload identity configuration may also be required.

Example fields:

```yaml
vaultUrl: <vault-url>
tenantId: <tenant-id>
```

---

## AWS Secrets Manager Configuration

For AWS environments:

```yaml
enkryptai:
  global:
    externalSecrets:
      clusterSecretStore:
        enabled: true
        provider: aws
```

Example fields:

```yaml
region: us-west-2
service: SecretsManager
```

---

# Ingress Configuration

Ingress is disabled by default.

Enable ingress only if external access to the platform is required.

Example:

```yaml
frontend:
  ingress:
    enabled: true
```

Added you domain in frontend, gateway-kong and supabase
```yaml
    hosts:
    - host: app.example.com # frontend

    hosts:
    - host: api.example.com  # gateway-kong

    hosts:
    - host: auth.example.com # supabase
```
---

# Traefik Configuration

Traefik installation is disabled by default.

Enable Traefik only if:

* your cluster does not already have an ingress controller
* you want EnkryptAI to manage the ingress controller deployment

Example:

```yaml
platform:
  traefik-stack:
    enabled: true
```

If another ingress controller already exists in the cluster, leave Traefik disabled.

---

# GPU-Based Components

The following components are disabled by default and should only be enabled if GPU workloads are required.

## Guardrails Model

```yaml
guardrails-model:
  enabled: true
```

Requirements:

* GPU-enabled Kubernetes nodes
* NVIDIA GPU Operator support
* Available GPU resources

---

## Guardrails Multi-Modal

```yaml
guardrails-multi-modal:
  enabled: true
```

Requirements:

* GPU-enabled Kubernetes nodes
* NVIDIA runtime support

---

# Guardrails Service

The guardrails service is optional and disabled by default.

Enable only if guardrails functionality is required.

Example:

```yaml
guardrails:
  enabled: true
```

---

# Storage Class Configuration

If the cluster does not have a default storage class, specify one explicitly.

Example:

```yaml
enkryptai:
  global:
    storageClass: managed-csi
```

---

# Image Pull Secrets

Image pull secrets are empty by default in several components.

If your deployment requires explicit image pull secret references, update the relevant sections.

Example:

```yaml
imagePullSecrets:
  - name: replicated-registry
```

---
> Note: If Using Azure cluster use azure-override values along with override values file. 
# Recommended Approach

Start with the minimum required deployment configuration and enable optional components incrementally.

Recommended deployment flow:

1. Configure registry access
2. Configure image pull secrets
3. Configure storage class
4. Enable ingress if required
5. Enable external secrets if required
6. Enable GPU workloads only if GPU nodes are available
7. Validate configuration before installation

---

# Example Installation Command

```bash
helm upgrade --install enkryptai \
  oci://<REGISTRY_URL>/<HELM_CHART> \
  -n enkryptai-stack \
  -f customer-override-values.yaml
```

For AKS deployments:

```bash
helm upgrade --install enkryptai \
  oci://<REGISTRY_URL>/<HELM_CHART> \
  -n enkryptai-stack \
  -f customer-override-values.yaml \
  -f azure-override-values.yaml
```
