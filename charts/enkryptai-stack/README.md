# Installation Steps

### 1️⃣ Install the **Platform Chart**

```bash
cd charts/platform/
helm dependency update
helm upgrade --install platform . -n enkryptai-stack -f values.yaml
```

### 2️⃣ Install the **EnkryptAI Stack Chart**

```bash
cd ../enkryptai-stack/
helm dependency update
helm upgrade --install enkryptai . -n enkryptai-stack -f values.yaml
```

> ✅ Once both charts are installed, your EnkryptAI environment should be fully operational on EKS.


