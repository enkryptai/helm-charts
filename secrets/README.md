# EnkryptAI Stack - Kubernetes Secrets

This directory contains template YAML files for all 14 Kubernetes secrets required by the EnkryptAI stack. These secrets must be created **before** installing the Helm charts.

## Quick Start

1. Copy and fill in each secret template with your actual values
2. Create the namespaces:
   ```bash
   kubectl create namespace enkryptai-stack
   kubectl create namespace redteam-jobs
   ```
3. Apply secrets in the recommended order below:
   ```bash
   kubectl apply -f secrets/
   ```

---

## Secrets Overview

| # | Secret Name | Namespace | Used By | File |
|---|-------------|-----------|---------|------|
| 1 | `frontend-env-secret` | `enkryptai-stack` | Frontend (Next.js dashboard) | [frontend-env-secret.yaml](frontend-env-secret.yaml) |
| 2 | `gateway-env-secret` | `enkryptai-stack` | Kong API Gateway | [gateway-env-secret.yaml](gateway-env-secret.yaml) |
| 3 | `gateway-migration-env-secret` | `enkryptai-stack` | Kong Gateway DB Migration Job | [gateway-migration-env-secret.yaml](gateway-migration-env-secret.yaml) |
| 4 | `guardrails-env-secret` | `enkryptai-stack` | Guardrails Service | [guardrails-env-secret.yaml](guardrails-env-secret.yaml) |
| 5 | `elastic-env-secret` | `enkryptai-stack` | Elasticsearch / Fluent Bit | [elastic-env-secret.yaml](elastic-env-secret.yaml) |
| 6 | `onprem` | `enkryptai-stack` | Supabase (Auth, DB, API) | [onprem.yaml](onprem.yaml) |
| 7 | `openfga-env-secret` | `enkryptai-stack` | OpenFGA (Authorization) | [openfga-env-secret.yaml](openfga-env-secret.yaml) |
| 8 | `opensearch-cred` | `enkryptai-stack` | OpenSearch | [opensearch-cred.yaml](opensearch-cred.yaml) |
| 9 | `opensearch-securityconfig` | `enkryptai-stack` | OpenSearch Security Plugin | [opensearch-securityconfig.yaml](opensearch-securityconfig.yaml) |
| 10 | `postgres-superuser-secret` | `enkryptai-stack` | PostgreSQL | [postgres-superuser-secret.yaml](postgres-superuser-secret.yaml) |
| 11 | `superuser-secret` | `enkryptai-stack` | Application DB access | [superuser-secret.yaml](superuser-secret.yaml) |
| 12 | `s3-cred` | `enkryptai-stack` | S3-compatible object storage | [s3-cred.yaml](s3-cred.yaml) |
| 13 | `litellm-gateway-env-secret` | `enkryptai-stack` | LiteLLM Gateway | [litellm-gateway-env-secret.yaml](litellm-gateway-env-secret.yaml) |
| 14 | `redteam-proxy-env-secret` | `redteam-jobs` | Red Team Proxy | [redteam-proxy-env-secret.yaml](redteam-proxy-env-secret.yaml) |

---

## Recommended Creation Order

Create secrets in this order to satisfy dependencies:

### Phase 1: Infrastructure Secrets (no dependencies)
These are foundational — other services depend on them.

1. **`postgres-superuser-secret`** — PostgreSQL superuser credentials
2. **`superuser-secret`** — Application-level database connection parameters
3. **`s3-cred`** — S3-compatible object storage credentials
4. **`onprem`** — Supabase core configuration (Postgres password, JWT secret, API keys)
5. **`opensearch-cred`** — OpenSearch credentials
6. **`opensearch-securityconfig`** — OpenSearch security plugin configuration

### Phase 2: Service Secrets (depend on infrastructure)
These reference infrastructure endpoints and credentials from Phase 1.

7. **`openfga-env-secret`** — OpenFGA database connection (depends on PostgreSQL)
8. **`elastic-env-secret`** — Elasticsearch connection details
9. **`guardrails-env-secret`** — Guardrails API keys and configuration
10. **`litellm-gateway-env-secret`** — LiteLLM proxy configuration (depends on PostgreSQL)

### Phase 3: Gateway Secrets (depend on services)
These reference service endpoints configured in Phase 2.

11. **`gateway-migration-env-secret`** — Kong DB migration (depends on PostgreSQL)
12. **`gateway-env-secret`** — Kong full configuration (depends on all upstream services)

### Phase 4: Application Secrets (depend on gateway and services)
These reference the gateway and all upstream services.

13. **`frontend-env-secret`** — Frontend configuration (depends on Kong, Supabase, OpenFGA)
14. **`redteam-proxy-env-secret`** — Red team proxy (depends on Supabase, S3, Redis)

---

## Notes

- **Never commit real secret values to version control.** These templates contain only placeholder values.
- Secret `#14` (`redteam-proxy-env-secret`) is deployed in the `redteam-jobs` namespace, while all others go in `enkryptai-stack`.
- For the `opensearch-securityconfig` secret, you need to generate a bcrypt hash of your admin password. See the comments in the template file for instructions.
- The `onprem` secret contains Supabase JWT keys (`ANON_KEY`, `SERVICE_ROLE_KEY`) which are JWTs signed with the `JWT_SECRET`. Use the [Supabase JWT generator](https://supabase.com/docs/guides/self-hosting#api-keys) to create these.
- Values shared across multiple secrets (e.g., PostgreSQL credentials, S3 keys) must be consistent between all secrets that reference them.
