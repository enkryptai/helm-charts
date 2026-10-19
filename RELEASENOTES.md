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
| `enkryptai-stack` | `charts/enkryptai-stack` | 1.2.0          |
| `platform-stack`  | `charts/platform`        | 1.2.1          |
| `platform-core`   | `charts/platform-core`   | 1.3.0          |

## 2026-10-19 — Compliance scan and OpenSearch sync (`platform-stack`)

| Chart            | Version          | Pull request |
| ---------------- | ---------------- | ------------ |
| `platform-stack` | 1.2.0 → 1.2.1   | [#128](https://github.com/enkryptai/helm-charts/pull/128) |

### Added

- **platform-stack:** New Supabase migrations `049-add-compliance-scans-table.sql`
  through `057-audit-export-projects-read.sql`, covering the compliance scans
  and log files tables, compliance aggregate functions and indexes,
  `project_credits_usage.updated_at`, Anthropic compliance support, and audit
  export. The `supabase-migration` ConfigMap now matches the apiaas
  `migration-sql.yaml`.
- **platform-stack:** OpenSearch index templates for `compliance`
  (`compliance-*`, priority 500), `compliance_policy_configs` (priority 600)
  and `mcp-scanner` (data stream).
- **platform-stack:** The `compliance_retention_policy` ISM policy for the
  compliance index. It rolls over and then freezes, and has no delete state.
- **platform-stack:** The `opensearch-compliance-bootstrap` hook job
  (`post-install`/`post-upgrade`, weight 22). It waits for the templates and
  policies, then creates `compliance-000001` with the write alias `compliance`
  and the `compliance_policy_configs` index. It skips anything that already
  exists.
- **platform-stack:** The `rollover_policy` ISM policy, which every index
  template already referenced but the chart never created.

### Changed

- **platform-stack:** The `admin`, `ai-proxy`, `guardrails` and `red_teaming`
  index templates were regenerated from `scripts/install/opensearch` in the
  apiaas repo. They add the audit, credit-metering, policy-violation rules,
  questionnaire, rate-limit and Red Team v2 request and response fields, and
  the six `guardrails` `dynamic_templates`. Thirty-two `red_teaming` fields
  changed from `keyword` to `text` with a `.keyword` sub-field. The `red_teaming`
  template now also sets the `rollover_policy` ISM settings. Replica counts and
  the `red_teaming` `total_fields.limit` (3000) are unchanged. Template changes
  apply to new indices only, so existing data streams pick them up at their
  next rollover.
- **platform-stack:** `rollover_policy` auto-attaches to `otel-*`, `admin`,
  `guardrails`, `ai-proxy`, `leaderboard`, `red_teaming` and `.ds-*` at priority
  1000. It rolls over at 1 day or 10gb per primary shard, goes read-only at 15
  days and deletes at 30 days.

### Removed

- **platform-stack:** The `rollbar-policy` ISM policy (`ism-policy.yaml`). It is
  replaced by `rollover_policy`, so `otel-*` retention changes from 15 to 30
  days, and the replica-count and force-merge steps are gone. On existing
  clusters the old policy object is not deleted automatically; remove it with
  `kubectl delete opensearchismpolicy rollbar-policy -n <namespace>`.
  The `opensearch.ism.*` values are now unused.

### Notes

- The compliance indices, ISM policy and templates created here are what the
  `compliance-scan` app in `enkryptai-stack` 1.2.1 expects: the alias
  `compliance`, the index `compliance_policy_configs` and the policy
  `compliance_retention_policy`.
- The `opensearch-compliance-bootstrap` job needs the OpenSearch `admin` user to
  hold `all_access`, which comes from the security config.

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
