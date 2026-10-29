## Pre-Installation Step: Set Your Domain URLs

Before installing the **EnkryptAI Stack**, set the following URLs to your **custom domain values** in your `enkryptai-stack` values file (for example `values/enkryptai-stack.yaml`).

These values are required for proper configuration of the **Frontend**, **Auth**, and **API** components.

> **Do not put these URLs in Kubernetes Secrets.** Each component loads its Secret first and the chart's ConfigMap after it, and the ConfigMap always contains these keys. A URL set in a Secret is silently replaced by the ConfigMap value. Secrets are for credentials (keys, passwords, tokens) and the per-install OpenFGA IDs below.

---

### 1. Frontend

**Values key:** `frontend.configMap.data`

| Key | Description | Example Value |
|-----|--------------|----------------|
| `NEXT_PUBLIC_APIAAS_KONG_URL` | API Gateway endpoint | `https://api.<domain.com>` |
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase (Auth) endpoint | `https://auth.<domain.com>` |
| `NEXT_PUBLIC_URL` | Frontend endpoint | `https://app.<domain.com>` |

---

### 2. Auth (Supabase GoTrue)

**Values key:** `supabase.configMap.data`

| Key | Description | Example Value |
|-----|--------------|----------------|
| `API_EXTERNAL_URL` | External API endpoint | `https://app.<domain.com>` |
| `GOTRUE_ADDITIONAL_REDIRECT_URLS` | Allowed redirect URLs | `http://localhost:3000/red-teaming, http://localhost:3000/**, https://app.<domain.com>/**` |
| `GOTRUE_EXTERNAL_REDIRECT_URLS` | Auth redirect callback URLs | `http://localhost:3000/api/auth/callback, https://auth.<domain.com>/api/auth/callback` |
| `GOTRUE_MAILER_EXTERNAL_HOSTS` | Hosts allowed in email links | `auth.<domain.com>,app.<domain.com>` |
| `GOTRUE_SITE_URL` | Primary site URL | `https://app.<domain.com>/` |
| `SUPABASE_PUBLIC_URL` | Supabase public endpoint | `https://auth.<domain.com>` |

---

### 3. Red Team Proxy

**Values key:** `redteam-proxy.configMap.data` (the chart writes this ConfigMap to both `enkryptai-stack` and `redteam-jobs`)

| Key | Description | Example Value |
|-----|--------------|----------------|
| `SUPABASE_URL` | Supabase Auth endpoint | `https://auth.<domain.com>` |

---

### 4. OpenFGA Store and Model IDs

The `openfga-sync` Job creates the OpenFGA store and authorization model on the first install, so the IDs are different for every installation. They are not in the chart's ConfigMaps; set them in these Secrets after the first install:

| Secret | Keys |
|--------|------|
| `frontend-env-secret` | `FGA_STORE_ID`, `FGA_MODEL_ID` |
| `gateway-env-secret` | `DECK_OPENFGA_STORE_ID`, `DECK_OPENFGA_AUTHORIZATION_MODEL_ID` |

Both components must use the same store and model. Restart `frontend` and `gateway-kong` after changing them.

---

### Example

```yaml
frontend:
  configMap:
    data:
      NEXT_PUBLIC_URL: "https://app.<domain.com>"
      NEXT_PUBLIC_APIAAS_KONG_URL: "https://api.<domain.com>"
      NEXT_PUBLIC_SUPABASE_URL: "https://auth.<domain.com>"

supabase:
  configMap:
    data:
      API_EXTERNAL_URL: https://app.<domain.com>
      GOTRUE_SITE_URL: https://app.<domain.com>
      SUPABASE_PUBLIC_URL: https://auth.<domain.com>
      GOTRUE_EXTERNAL_REDIRECT_URLS: http://localhost:3000/api/auth/callback,https://auth.<domain.com>/api/auth/callback
      GOTRUE_ADDITIONAL_REDIRECT_URLS: http://localhost:3000/red-teaming, http://localhost:3000/**, https://app.<domain.com>/**
      GOTRUE_MAILER_EXTERNAL_HOSTS: auth.<domain.com>,app.<domain.com>

redteam-proxy:
  configMap:
    data:
      SUPABASE_URL: "https://auth.<domain.com>"
```

---

### Important Notes

- Replace all occurrences of `<domain.com>` with your actual base domain (e.g., `enkryptai.io` or `example.com`).
- Set these values **before deploying** the EnkryptAI Helm charts. To change them later, update the values file and run `helm upgrade`.
- If using AWS ALB, make sure ACM certificates are valid for:
  - `app.<domain.com>`
  - `auth.<domain.com>`
  - `api.<domain.com>`
