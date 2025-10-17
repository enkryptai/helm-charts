# Installation Steps

### 1️⃣ Install the **Platform Chart**

Here’s a clean, professional Markdown note you can drop right into your repo 👇

---

## 📝 Note

The **values file** will be provided by the **EnkryptAI team**.
Before installing any Helm chart, please ensure that all **required Kubernetes Secrets** are already created and available in the target namespace.
For more info check https://enkryptai.github.io/helm-charts/

```bash
helm repo add enkryptai  https://enkryptai.github.io/helm-charts/
helm repo update
helm upgrade --install platform enkryptai/platform-stack -n enkryptai-stack -f values.yaml --timeout 15m
```

### 2️⃣ Install the **EnkryptAI Stack Chart**

```bash
helm repo add enkryptai  https://enkryptai.github.io/helm-charts/
helm repo update
helm upgrade --install enkryptai enkryptai/enkryptai-stack -n enkryptai-stack -f values.yaml --timeout 15m
```

> ✅ Once both charts are installed, your EnkryptAI environment should be fully operational.


