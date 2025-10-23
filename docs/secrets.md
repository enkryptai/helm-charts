## Pre-Installation Step: Update Domain Secrets

Before installing the **EnkryptAI Stack**, make sure to update the following Kubernetes secrets with your **custom domain values**.

These secrets are required for proper configuration of the **Frontend**, **Auth**, and **API** components.

---

### 1. `frontend-env-secret`

**Namespace:** `enkryptai-stack`

Update the following keys with your domain-specific URLs:

| Key | Description | Example Value |
|-----|--------------|----------------|
| `NEXT_PUBLIC_APIAAS_KONG_URL` | API Gateway endpoint | `https://api.<domain.com>` |
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase (Auth) endpoint | `https://auth.<domain.com>` |
| `NEXT_PUBLIC_URL` | Frontend endpoint | `https://app.<domain.com>` |

---

### 2. `onprem` Secret

**Namespace:** `enkryptai-stack`

Update the keys below to match your custom domains:

| Key | Description | Example Value |
|-----|--------------|----------------|
| `API_EXTERNAL_URL` | External API endpoint | `https://app.<domain.com>` |
| `GOTRUE_ADDITIONAL_REDIRECT_URLS` | Allowed redirect URLs | `http://localhost:3000/red-teaming, http://localhost:3000/**, https://app.<domain.com>/**` |
| `GOTRUE_EXTERNAL_REDIRECT_URLS` | Auth redirect callback URLs | `http://localhost:3000/api/auth/callback, https://auth.<domain.com>/api/auth/callback` |
| `GOTRUE_SITE_URL` | Primary site URL | `https://app.<domain.com>/` |
| `SUPABASE_PUBLIC_URL` | Supabase public endpoint | `https://auth.<domain.com>` |

---

### 3. `redteam-proxy-env-secret`

**Namespaces:**  
- `enkryptai-stack`  
- `redteam-jobs`

Update the following key:

| Key | Description | Example Value |
|-----|--------------|----------------|
| `SUPABASE_URL` | Supabase Auth endpoint | `https://auth.<domain.com>` |

---

### Important Notes

- Replace all occurrences of `<domain.com>` with your actual base domain (e.g., `enkryptai.io` or `example.com`).
- Ensure all secrets are updated **before deploying** the EnkryptAI Helm charts.
- If using AWS ALB, make sure ACM certificates are valid for:
  - `app.<domain.com>`
  - `auth.<domain.com>`
  - `api.<domain.com>`

