# Installation Steps

### 1️⃣ Install the **Platform Chart**


---

## Note

The **values file** will be provided by the **EnkryptAI team**.
Before installing any Helm chart, please ensure that all **required Kubernetes Secrets** are already created and available in the target namespace.
For more info check https://enkryptai.github.io/helm-charts/

```bash
helm repo add enkryptai  https://enkryptai.github.io/helm-charts/
helm repo update
helm upgrade --install platform enkryptai/platform-stack -n enkryptai-stack -f values.yaml --timeout 15m
```

### 2️⃣ Install the **EnkryptAI Stack Chart**

Don't forget to apply below configmap 
```
kubectl apply -f https://raw.githubusercontent.com/enkryptai/helm-charts/refs/heads/main/charts/enkryptai-stack/gateway-temp-config-map.yaml
```

```bash
helm repo add enkryptai  https://enkryptai.github.io/helm-charts/
helm repo update
helm upgrade --install enkryptai enkryptai/enkryptai-stack -n enkryptai-stack -f values.yaml --timeout 15m
```

---

###  Post-Installation Steps-1: Update Required Secrets

Once **both charts** have been successfully installed, you’ll need to update the following **Kubernetes secrets** with your OpenFGA configuration values.

> You can find `authorization_model_id` and `store_id` in the **OpenFGA logs**.

#### 1. Frontend

**Secret Name:** `frontend-env-secret`
Update the following environment variables:

```
FGA_STORE_ID=<store_id>
FGA_MODEL_ID=<authorization_model_id>
```

#### 2. Gateway (Kong)

**Secret Name:** `gateway-env-secret`
Update the following environment variables:

```
DECK_OPENFGA_STORE_ID=<store_id>
DECK_OPENFGA_AUTHORIZATION_MODEL_ID=<authorization_model_id>
```
---
### Note: Restart Deployments After Updating Secrets
Once the secrets have been updated, restart the deployments to ensure the new environment variables are loaded.
Run the following commands:
```sh
kubectl rollout restart deployment frontend -n enkryptai-stack
kubectl rollout restart deployment gateway-kong -n enkryptai-stack
```
---

###  Post-Installation Steps-2: Provide SSL Certificates for Your Domains 

Before you start using the **EnkryptAI Stack**, ensure the following subdomains are properly configured and secured with valid SSL/TLS certificates:

1. **app.<domain>** — Used by **EnkryptAI Frontend**
2. **auth.<domain>** — Used by **EnkryptAI Auth Service**
3. **api.<domain>** — Used by **EnkryptAI Kong (API Gateway)**

> Example:
> If your base domain is `example.com`, the stack will use:
>
> ```
> app.example.com
> auth.example.com
> api.example.com
> ```

Make sure you:
* Create DNS records for each subdomain.
* Attach valid SSL certificates for all three before deploying EnkryptAI Stack.


If you encounter any issues during installation or post-deployment, please reach out to the EnkryptAI DevOps team for assistance and troubleshooting.
