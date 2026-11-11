## Pre-Installation Step: Set Your Domain

Before installing the **EnkryptAI Stack**, set `global.domain` in your `enkryptai-stack` values file (for example `values/enkryptai-stack.yaml`). Every Ingress host and every public URL in the chart derives from it.

```yaml
global:
  domain: company.com
```

> **Do not put these URLs in Kubernetes Secrets.** Each component loads its Secret first and the chart's ConfigMap after it, and the ConfigMap always contains these keys. A URL set in a Secret is silently replaced by the ConfigMap value. Secrets are for credentials (keys, passwords, tokens) and the per-install OpenFGA IDs below.

---

### 1. Hosts

| Host | Values key | Component |
|------|------------|-----------|
| `app.<domain>` | `frontend.ingress` | Frontend (web app) |
| `api.<domain>` | `gateway-kong.ingress` | API gateway |
| `auth.<domain>` | `supabase.ingress` | Auth (Supabase) |
| `compliance-scan.<domain>` | `compliance-scan.ingress` | Compliance scan (off by default) |
| `leaderboard.<domain>` | `leaderboard-client.ingress` | Leaderboard (off by default) |
| `leaderboard-server.<domain>` | `leaderboard-server.ingress` | Leaderboard API (off by default) |
| `mcpscanner.<domain>` | `mcp-scanner.ingress` | MCP scanner (off by default) |
| `skill-scanner.<domain>` | `skill-scanner.ingress` | Skill scanner (off by default) |
| `mcp.<domain>` | `secure-mcp-gateway.ingress` | Secure MCP gateway (off by default) |

Each Ingress uses the host in both `hosts` and `tls`. Ingresses are off by default; turn on the ones you expose with `<component>.ingress.enabled: true`.

---

### 2. URLs in the ConfigMaps

| Values key | Keys | Default |
|------------|------|---------|
| `frontend.configMap` | `NEXT_PUBLIC_URL`, `NEXT_PUBLIC_APIAAS_KONG_URL`, `NEXT_PUBLIC_SUPABASE_URL` | `https://app.<domain>`, `https://api.<domain>`, `https://auth.<domain>` |
| `supabase.configMap` | `API_EXTERNAL_URL`, `GOTRUE_SITE_URL` | `https://app.<domain>` |
| `supabase.configMap` | `SUPABASE_PUBLIC_URL` | `https://auth.<domain>` |
| `supabase.configMap` | `GOTRUE_EXTERNAL_REDIRECT_URLS`, `GOTRUE_EXTERNAL_GOOGLE_REDIRECT_URI` | callback URLs on `auth.<domain>` |
| `supabase.configMap` | `GOTRUE_ADDITIONAL_REDIRECT_URLS`, `GOTRUE_MAILER_EXTERNAL_HOSTS` | `app.<domain>` and `auth.<domain>` entries |
| `redteam-proxy.configMap` | `SUPABASE_URL` | `https://auth.<domain>` (the chart writes this ConfigMap to both `enkryptai-stack` and `redteam-jobs`) |
| `compliance-scan.configMap` | `SUPABASE_URL` | `https://auth.<domain>` |

---

### 3. Use a different host or URL for one component

An explicit value wins over the derived one. Ingress hosts and the ConfigMap values above go through `tpl`, so an override can still use `{{ .Values.global.domain }}`:

```yaml
frontend:
  ingress:
    hosts:
      - host: portal.company.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - hosts:
          - portal.company.com
        secretName: frontend-cert
  configMap:
    NEXT_PUBLIC_URL: "https://portal.company.com"

supabase:
  configMap:
    GOTRUE_SITE_URL: "https://portal.{{ .Values.global.domain }}"
```

A list such as `ingress.hosts` replaces the default list, so give the whole list. Because these values go through `tpl`, a literal `{{` in them must be escaped.

---

### 4. OpenFGA Store and Model IDs

The `openfga-sync` Job creates the OpenFGA store and authorization model on the first install, so the IDs are different for every installation. They are not in the chart's ConfigMaps; set them in these Secrets after the first install:

| Secret | Keys |
|--------|------|
| `frontend-env-secret` | `FGA_STORE_ID`, `FGA_MODEL_ID` |
| `gateway-env-secret` | `DECK_OPENFGA_STORE_ID`, `DECK_OPENFGA_AUTHORIZATION_MODEL_ID` |

Both components must use the same store and model. Restart `frontend` and `gateway-kong` after changing them.

---

### Important Notes

- Set `global.domain` **before deploying** the EnkryptAI Helm charts. To change it later, update the values file and run `helm upgrade`.
- Create DNS records and TLS certificates for every host you expose. If using AWS ALB, make sure ACM certificates are valid for:
  - `app.<domain>`
  - `auth.<domain>`
  - `api.<domain>`
