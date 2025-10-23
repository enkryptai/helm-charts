# Installation Steps

### 1️⃣ Install the **Platform Chart**

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

###  Post-Installation: Update Required Secrets

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
### Note: Restart Deployments After Updating Secrets
Once the secrets have been updated, restart the deployments to ensure the new environment variables are loaded.
Run the following commands:
```sh
kubectl rollout restart deployment frontend -n enkryptai-stack
kubectl rollout restart deployment gateway-kong -n enkryptai-stack
```


