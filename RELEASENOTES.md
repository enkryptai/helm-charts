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
| `platform-stack`  | `charts/platform`        | 1.2.2          |
| `platform-core`   | `charts/platform-core`   | 1.3.0          |

## Unreleased — On-prem review fixes (`enkryptai-stack`)

Merged to `main`, not published yet. These changes ship together in
`enkryptai-stack` 1.2.2; the release PR adds the version bump, the package and
the `index.yaml` entry.

| Change | Pull request |
| ------ | ------------ |
| Default image tags match the 1.2.1 image lock | [#137](https://github.com/enkryptai/helm-charts/pull/137) |

### Upgrading from 1.2.1

- **Image tags (#137).** Mirror the new tags to your registry before
  upgrading. Supabase moves to Kong `3.6.1` (from `2.8.1`) and GoTrue
  `v2.174.0` (from `v2.169.0`); the Supabase helper Jobs use the
  `postgres:18.3-alpine3.22` client (from `15-alpine`). Tags set in your values
  file still win over these defaults.

### Changed

- **enkryptai-stack:** every default image tag now matches the 1.2.1 image
  lock, in `values.yaml` and in each subchart's own defaults:

  | Image | Before | After |
  | ----- | ------ | ----- |
  | `enkryptai-prod/frontend` | `7961f95` | `ffa3bdf` |
  | `enkryptai-prod/gateway`, `gateway-sync` | `dev-1767798930`, `a8a9b2c` | `ffa3bdf` |
  | `enkryptai-prod/guardrails` | `prodgr-v0.0.5` | `prodgr-v0.0.47-1792756790` |
  | `enkryptai-prod/guardrail-model`, `guardrail-multimodal` | `main-1771906796`, `ddc789c` | `5b5d164` |
  | `enkryptai-prod/litellm-gateway` | `main-1771906797` | `5b5d164` |
  | `enkryptai-prod/redteam-proxy` | `prod-v1.0.68` | `prod-v1.0.98-1789540682` |
  | `enkryptai-prod/compliance-scan` | `main` | `bd51716` |
  | `enkryptai-prod/leaderboard-client`, `leaderboard-server` | `main` | `ffa3bdf` |
  | `enkryptai-prod/mcp-scanner` | `main` | `main-1792760481` |
  | `enkryptai-prod/secure-mcp-gateway` | `main` | `b5b270d` |
  | `enkryptai-prod/openfga-sync` | `v1.11.0` | `v1.13.0` |
  | `onprem/busybox` | `latest` | `uclibc` |
  | `onprem/minio` | `latest` | `RELEASE.2025-09-07T16-13-09Z-cpuv1` |
  | `onprem/gotrue` | `v2.169.0` | `v2.174.0` |
  | `onprem/kong` (Supabase) | `2.8.1` | `3.6.1` |
  | `onprem/curljq` | `latest` | `ubuntu` |
  | `onprem/postgres` (Supabase Jobs) | `15-alpine` | `18.3-alpine3.22` |

- **enkryptai-stack:** the `redteam-proxy` subchart default pointed at
  `enkryptai-dev/redteam-proxy:dev`; it now uses `enkryptai-prod`.

### Fixed

- **enkryptai-stack:** Supabase storage `mc` image typo `onprem/mc:lastest` →
  `onprem/mc:latest`.

## 2026-10-29 — On-prem review fixes (`platform-stack`)

| Chart            | Version         | Pull request |
| ---------------- | --------------- | ------------ |
| `platform-stack` | 1.2.1 → 1.2.2   | [#132](https://github.com/enkryptai/helm-charts/pull/132) |

### Upgrading from 1.2.1

Do these before `helm upgrade` of an existing `platform-stack` release:

1. **Adopt the Argo Workflows CRDs.** The 1.2.1 CRD install Job applied them
   outside Helm, and Helm now renders them, so the upgrade fails with
   "invalid ownership metadata" until they are adopted (replace `platform`
   with your release name):

   ```bash
   for c in clusterworkflowtemplates cronworkflows workflowartifactgctasks \
            workfloweventbindings workflows workflowtaskresults workflowtasksets \
            workflowtemplates; do
     kubectl label crd $c.argoproj.io app.kubernetes.io/managed-by=Helm --overwrite
     kubectl annotate crd $c.argoproj.io meta.helm.sh/release-name=platform \
       meta.helm.sh/release-namespace=enkryptai-stack --overwrite
   done
   ```

   **Releases installed with Helm 4 only.** Check the apply method first:

   ```bash
   helm get metadata platform -n enkryptai-stack -o json | jq -r .applyMethod
   ```

   If it prints `ssa`, also run the step below after the loop above. Helm 4
   applies server-side, and the 1.2.1 Job's server-side apply left `kubectl`
   owning the CRD fields, so without this step the upgrade fails with
   `conflict with "kubectl": .spec.versions` on `clusterworkflowtemplates`,
   `cronworkflows`, `workflows` and `workflowtemplates`. That failed upgrade is
   a partial apply (it rolls the EventBus), so run this step first instead of
   retrying. No `--force-conflicts` is needed. Releases installed with Helm 3
   don't need it, even when upgraded with Helm 4.

   ```bash
   for c in clusterworkflowtemplates cronworkflows workflowartifactgctasks \
            workfloweventbindings workflows workflowtaskresults workflowtasksets \
            workflowtemplates; do
     i=$(kubectl get crd $c.argoproj.io --show-managed-fields -o json | jq '[.metadata.managedFields[].manager] | index("kubectl")')
     [ "$i" = null ] || kubectl patch crd $c.argoproj.io --type=json \
       -p "[{\"op\":\"test\",\"path\":\"/metadata/managedFields/$i/manager\",\"value\":\"kubectl\"},{\"op\":\"remove\",\"path\":\"/metadata/managedFields/$i\"}]"
   done
   ```
2. **Kong database password.** Put a new `KONG_PG_PASSWORD` in both
   `gateway-migration-env-secret` and `gateway-env-secret`, run
   `helm upgrade`, then restart `gateway-kong`. The `db-check-and-grant` Job
   sets the database password from the Secret on upgrade, so no manual
   `ALTER USER` is needed. Both Secrets must hold the same value, or Kong
   fails on its next restart. Treat the old password as compromised: it was
   published in `006-create-kong.sql` in 1.2.0 and 1.2.1.
3. **GPU operator.** Set `platform-core.gpu-operator.enabled: true` if the
   cluster uses it. Upgrading without it removes the GPU operator.
4. Replace `backup.*` values, if set, with `supabase.backup` /
   `openfga.backup` (see Added).

### Added

- **platform-stack:** `supabase.backup`, `supabase.plugins`, `openfga.backup`
  and `openfga.plugins`, rendered as-is into each CNPG Cluster's
  `spec.backup` / `spec.plugins` (CNPG 1.29: prefer the Barman Cloud plugin).
  Off by default. The Clusters are post-install hooks, so the values apply to
  fresh installs only; on an existing install patch the Cluster directly.
- **platform-stack:** `databasekong.passwordSecret.{name,key}` (default
  `gateway-migration-env-secret` / `KONG_PG_PASSWORD`).

### Changed

- **platform-stack:** `platform-core.argo-workflows.crds.full: false`. Helm
  renders the minimal Argo Workflows CRDs; the CRD install Job, its GitHub
  download and the `registry.k8s.io/kubectl` image are gone.
- **platform-stack:** `platform-core.gpu-operator.enabled: false` by default.
- **platform-stack:** The `db-check-and-grant` Job creates the `kong` role if
  missing and sets its password from the Secret through `psql -v`; it fails if
  the password is empty. It no longer runs `secrets.supabase.kong.sql`.
- **platform-stack:** The migration Job runs each file with
  `ON_ERROR_STOP=1` (a failing file is no longer recorded as applied) and
  sorts with `LC_ALL=C`. Files without their own `BEGIN` run with `psql -1`
  together with their history row, so a failed file leaves nothing behind
  and the retry can run it again. The Job fails if the tracking table or the
  history check fails, instead of skipping every file.
- **platform-stack:** `KONG_PG_PASSWORD` is read with `optional: true`, so a
  missing Secret fails the Job fast instead of hanging until the Helm timeout.
- **platform-stack:** Migrations: `002b` no longer creates
  `filter_invitations_by_project`; `006-create-kong.sql` is an empty
  placeholder; `023`/`024` skip the `recent_signups` view until GoTrue has
  added `auth.users.email_confirmed_at`; `048` and `054` synced from apiaas.
  These edits reach fresh installs only: the Job never re-runs a file it has
  recorded, so upgraded databases keep the old version.
- **platform-stack:** Image tags: Supabase Postgres `16.0.3`, redteam-job
  `prod-v1.0.98`, busybox `uclibc`, k8s-driver-manager `v0.10.0`, vfio
  manager CUDA `12.6.2-base-ubi9`, valkey `9.1.2`, nats config reloader
  `0.23.0`.

### Removed

- **platform-stack:** The second migration Job `db-migration-supabase`
  (`migration.yaml`), which ran without tracking.
- **platform-stack:** Unused `backup.openfgsS3Bucket`,
  `backup.supabaseS3Bucket` and `secrets.supabase.kong.sql`.
- `enkryptai-lite` from the README and troubleshooting docs.

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
