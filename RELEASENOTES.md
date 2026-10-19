# Release Notes

All notable changes to the EnkryptAI Helm charts are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and each chart is versioned independently according to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Because this repository publishes several charts with independent version
numbers, entries are grouped by **release date**. Each entry lists the chart
versions it published, and every change is prefixed with the chart it affects.

| Chart             | Path                     | Latest version |
| ----------------- | ------------------------ | -------------- |
| `enkryptai-stack` | `charts/enkryptai-stack` | 1.2.1          |
| `platform-stack`  | `charts/platform`        | 1.2.0          |
| `platform-core`   | `charts/platform-core`   | 1.3.0          |

## 2026-10-19 — New scanner apps and gateway config sync (`enkryptai-stack`)

| Chart             | Version          | Pull request |
| ----------------- | ---------------- | ------------ |
| `enkryptai-stack` | 1.2.0 → 1.2.1   | [#129](https://github.com/enkryptai/helm-charts/pull/129) |

### Added

- **enkryptai-stack:** Six new application subcharts: `compliance-scan`,
  `leaderboard-client`, `leaderboard-server`, `mcp-scanner`,
  `secure-mcp-gateway` and `skill-scanner`. Each has a matching block in
  `values.yaml` and every one is **disabled by default** (`enabled: false`).
- **enkryptai-stack:** `compliance-scan` expects the compliance OpenSearch
  alias (`compliance`), the `compliance_policy_configs` index, the
  `compliance_retention_policy` ISM policy and Supabase migrations 049 to 057.
  Install `platform-stack` 1.2.1 first, which creates them.
- **enkryptai-stack:** The gateway-kong `fluent-bit` container now reads its
  `envFrom` from `gateway-kong.image.fluentBit.envFrom`. The default is the
  secret `elastic-env-secret`, so existing installs render the same. Set the list
  to `[]` to add no environment sources.
- **enkryptai-stack:** New gateway-kong values for cache encryption:
  `configMap.gatewayEnv.ENKRYPT_CACHE_ENCRYPTION_ENABLED` (default `"false"`)
  and `secrets.gateway.ENKRYPT_CACHE_ENCRYPTION_KEY` (empty placeholder). Kong
  reads both through `{vault://env/enkrypt-cache-encryption-*}`. If you load
  the gateway secret from an external secret, add `ENKRYPT_CACHE_ENCRYPTION_KEY`
  there as well.

### Changed

- **enkryptai-stack:** `gateway-temp-config-map.yaml` was synced from the
  apiaas `gateway-kong-temp-config.yaml`. It adds cache encryption on the
  caching plugins, the `/compliance/*` and `/dashboard/compliance/*` routes, the
  `/rt/redteam/jailbreak` and `/rt/leaderboard` routes, and more scrubbed log
  fields (`model_config.apikeys`, `auth_data`, `compliance_api_key`). Red Team
  run reads (`/rt/runs/{id}`, `/results`, `/records`) now go through the
  db-proxy to Next.js.
- **enkryptai-stack:** The `openfgaSyncJob` image tag changed from `v1.3.0` to
  `v1.11.0`.
- **enkryptai-stack:** The `compliance-scan` ingress is disabled by default and
  its placeholder host is `compliance-scan.example.com`. It used to copy the
  Supabase host, and two ingresses on the same host and path send all Supabase
  traffic to `compliance-scan`.

### Removed

- **enkryptai-stack:** The legacy Red Team add-task, model-health and
  cancel-task routes, the playground `/attack` service and the
  `/public/rt/runs/...` routes are removed from the gateway config. The
  `/public/rt/redteam` route now matches exactly.

### Notes

- `gateway-temp-config-map.yaml` is applied by the `gateway-cm-job` from the
  `main` branch on GitHub, so the new gateway config only takes effect once this
  change is merged.
- `secure-mcp-gateway` reads AWS credentials from the secret `s3-credentials`
  (not the shared `s3-cred`, which holds Supabase Storage keys). It needs an IAM
  key that can `s3:GetObject` on `enkrypt_mcp_config.json` in its bucket.

## 2026-08-27 — Red Team v2

| Chart             | Version          | Pull request                                                 |
| ----------------- | ---------------- | ------------------------------------------------------------ |
| `enkryptai-stack` | 1.1.25 → 1.2.0   | [#125](https://github.com/enkryptai/helm-charts/pull/125)    |
| `platform-stack`  | 1.1.34 → 1.2.0   | [#125](https://github.com/enkryptai/helm-charts/pull/125)    |



### Breaking Changes

- **platform-stack:** The Red Team v1 Argo Events sensors and event sources
  (`redteam-attack`, `redteam-add-task`, `redteam-alignment-data`,
  `redteam-custom-task`, `redteam-generate-data`, `redteam-logs`) have been
  removed. They are replaced by one `redteam-run` sensor and event source that
  listens on the NATS subject `run.request`. Anything that still publishes to
  the old subjects (`attack.request`, `add-task.request`, `logs.attack`, and so
  on) will no longer trigger jobs.
- **platform-stack:** The Red Team job now reads the ConfigMap
  `redteam-proxy-env-cm` instead of `redteam-proxy-env-config`.


### Added

- **platform-stack:** `002b-public-schema.sql`, an idempotent migration that
  creates the 25 base application tables in the `public` schema. Earlier
  migrations depended on these tables. The migration runner does not stop on
  SQL errors, so without them more than 18 of those migrations rolled back
  without any visible failure. The script is safe to re-run: it uses
  `CREATE TABLE IF NOT EXISTS`, `CREATE OR REPLACE FUNCTION`, `DO` blocks with
  `pg_type` checks for enums, and `duplicate_object` exception handlers for
  constraints, generated columns, and policies.
- **platform-stack:** New Supabase migrations `005-custom-kong.sql` and
  `019-*` through `048-*`, covering Red Team v2 tables, RPCs, and indexes, the
  MCP registry and MCP hub usage, credit metering and project credit limits,
  organization secrets, Code of Conduct v2, skill scanner API usage, and
  function and RLS hardening.
- **platform-stack:** New value `sensor.natsURL` (default
  `nats://nats.enkryptai-stack:4222`) that sets the NATS endpoint for the
  `redteam-run` event source.
- **platform-stack:** New value `sensor.env` for environment variables passed
  to the Red Team job (defaults: `WORKER_TYPE`, `NATS_URL`, `IS_PROXY_MODE`,
  `RT_NATS_PAYLOAD`, `PYTHONPATH`).
- **platform-stack:** The `redteam-run` sensor now uses `global.imagePullSecrets`
  for the workflows it creates.
- **enkryptai-stack:** Red Team v2 relay settings for `redteam-proxy`
  (`RELAY_BACKPLANE`, `RELAY_DB_LOG`, `RELAY_ENDPOINT`, `RELAY_REDIS_URL`).
- **enkryptai-stack:** Supabase Auth settings for Azure and SAML sign-in
  (`GOTRUE_EXTERNAL_AZURE_*`, `GOTRUE_SAML_*`), plus `DB_DRIVER` and
  `S3_PROTOCOL_ALLOWS_SERVICE_KEY_AS_SECRET`.
- **enkryptai-stack:** New configuration keys `DECK_SKILL_SCANNER_URL`
  (gateway-kong) and `MCP_POD_URL` (frontend).
- **enkryptai-stack:** An `app.kubernetes.io/instance` label on the frontend,
  gateway-kong, guardrails, litellm, and supabase ConfigMaps.

### Changed

- **platform-stack:** The NATS URL default changed from `nats://nats.nats:4222`
  to `nats://nats.enkryptai-stack:4222`.
- **platform-stack:** The `redteam-run` event source and sensor are now Helm
  `post-install`/`post-upgrade` hooks (weights 5 and 10) and are deployed to
  the `argo-events` namespace.
- **enkryptai-stack:** The default Red Team models in litellm now point to
  Together AI (`MiniMaxAI/MiniMax-M3`, `google/gemma-4-31b-it`) and Gemini
  (`gemini-3.1-flash-lite`) instead of OpenAI, Mistral, Groq, and DeepSeek.
- **enkryptai-stack:** The default for frontend `DEFAULT_ENTERPRISE` changed
  from `true` to `false`.
- **enkryptai-stack:** The default for gateway-kong `KONG_LOG_LEVEL` changed
  from `debug` to `info`.
- **enkryptai-stack:** The gateway-kong key `DECK_VALKEY_HOST` was renamed back
  to `DECK_KEYDB_HOST`. It still points to `valkey`.
- **enkryptai-stack:** Updated the gateway-kong declarative configuration in
  `gateway-temp-config-map.yaml` for Red Team v2.

## 2026-08-03 — Valkey migration (`enkryptai-stack`)

| Chart             | Version           | Pull request                                                 |
| ----------------- | ----------------- | ------------------------------------------------------------ |
| `enkryptai-stack` | 1.1.24 → 1.1.25   | [#123](https://github.com/enkryptai/helm-charts/pull/123)    |

### Changed

- **enkryptai-stack:** Replaced KeyDB with Valkey in gateway-kong, guardrails,
  and redteam-proxy. `REDIS_URL` now points to `valkey` and gateway-kong uses
  `DECK_VALKEY_HOST`.
- **enkryptai-stack:** The litellm service port changed from `443` to `4000`.
- **enkryptai-stack:** Added gateway-kong tracing settings
  (`KONG_TRACING_INSTRUMENTATIONS: all`, `KONG_TRACING_SAMPLING_RATE: 0.03`)
  and `DECK_MCP_SCANNER_URL`.
- **enkryptai-stack:** Added `SENTRY_GR_MODEL_URL` to guardrails.

### CI

- The summary job in `helm-check.yaml` now requires the `template-validation`
  and `security-scan` jobs. `lint-and-test` and `version-check` no longer
  block it. ([#124](https://github.com/enkryptai/helm-charts/pull/124))

## 2026-07-31 — Valkey migration (`platform-stack`)

| Chart            | Version           | Pull request                                                 |
| ---------------- | ----------------- | ------------------------------------------------------------ |
| `platform-stack` | 1.1.33 → 1.1.34   | [#122](https://github.com/enkryptai/helm-charts/pull/122)    |

### Changed

- **platform-stack:** The `platform-core` dependency was upgraded from 1.2.1 to
  1.3.0, which uses Valkey instead of KeyDB.
- **platform-stack:** The `platform-core.keydb` values were replaced with
  `platform-core.valkey.image.*`.
- **platform-stack:** The Red Team Argo sensors now also load the
  `redteam-proxy-env-cm` ConfigMap.

## 2026-07-28 — Valkey migration (`platform-core`)

| Chart           | Version         | Pull request                                                 |
| --------------- | --------------- | ------------------------------------------------------------ |
| `platform-core` | 1.2.1 → 1.3.0   | [#121](https://github.com/enkryptai/helm-charts/pull/121)    |

### Changed

- **platform-core:** Replaced the KeyDB dependency (chart 0.48.0) with Valkey
  (chart 0.10.0, `https://valkey.io/valkey-helm/`). The `keydb` block in
  `values.yaml` is replaced by `valkey` (replicas, persistence, image), and
  `Chart.lock` was updated.

## 2026-06-19 — ConfigMap-based configuration

| Chart             | Version           | Pull request                                                 |
| ----------------- | ----------------- | ------------------------------------------------------------ |
| `enkryptai-stack` | 1.1.23 → 1.1.24   | [#118](https://github.com/enkryptai/helm-charts/pull/118)    |
| `platform-stack`  | 1.1.32 → 1.1.33   | [#118](https://github.com/enkryptai/helm-charts/pull/118)    |

### Added

- **enkryptai-stack:** ConfigMap templates for non-sensitive environment
  variables in gateway-kong (`gateway-env-cm`, `gateway-migration-env-cm`),
  guardrails, litellm, redteam-proxy, and supabase. Workloads load them
  through `envFrom.configMapRef`.

### Changed

- **enkryptai-stack:** Non-sensitive configuration moved from secrets to the
  ConfigMaps above. ExternalSecret templates remain available but are disabled
  by default (`externalSecrets.enabled: false`).
- **enkryptai-stack:** The frontend ingress is now disabled by default
  (`frontend.ingress.enabled: false`), and its TLS secret name changed from
  `custom-cert-front` to `frontend-cert`.

### Removed

- **platform-stack:** The bundled `external-secrets` (ESO) subchart dependency
  (2.3.0) and the ESO `wait-job` template. If you use External Secrets
  Operator, install it separately.
