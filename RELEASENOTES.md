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
| In-cluster URLs from the release name and namespace; no SaaS endpoints by default; OpenFGA IDs only from Secrets | [#138](https://github.com/enkryptai/helm-charts/pull/138) |
| browser-use telemetry and `litellm` metering off by default | [#146](https://github.com/enkryptai/helm-charts/pull/146) |
| `gateway-kong` ships its decK config in the chart instead of fetching it from GitHub at install | [#134](https://github.com/enkryptai/helm-charts/pull/134) |
| `litellm.serviceAccount` for workload identity (off by default) | [#147](https://github.com/enkryptai/helm-charts/pull/147) |
| OpenFGA migrations run before the Deployment, so `helm install --wait` doesn't hang | [#135](https://github.com/enkryptai/helm-charts/pull/135) |
| Fluent Bit memory limit `256Gi` → `256Mi` | [#136](https://github.com/enkryptai/helm-charts/pull/136) |
| Startup, readiness and liveness probes for every workload, set from values (new ones off by default, except `guardrails-model` startup/readiness and `gateway-kong` readiness) | [#139](https://github.com/enkryptai/helm-charts/pull/139) |
| `utils/post-installation.sh` reads the OpenFGA IDs from the OpenFGA API, not from pod logs | [#142](https://github.com/enkryptai/helm-charts/pull/142) |
| Supabase: `onprem` ConfigMap URLs use the release name (typo fixed); `analytics.enabled: true` renders again | [#143](https://github.com/enkryptai/helm-charts/pull/143) |
| `*-env-cm` and `onprem` ConfigMaps are normal release resources, not `pre-install`/`pre-upgrade` hooks | [#144](https://github.com/enkryptai/helm-charts/pull/144) |
| Kong tracing on in the gateway container (`KONG_TRACING_*` in `gatewayEnv`, 3% sampling) | [#154](https://github.com/enkryptai/helm-charts/pull/154) |

### Upgrading from 1.2.1

- **In-cluster URLs (#138).** The `litellm`, `guardrails` and `redteam-proxy`
  defaults now build Service URLs from `{{ .Release.Name }}` and
  `{{ .Release.Namespace }}`, and these ConfigMap values and the
  `guardrails` / `redteam-proxy` `env` values go through `tpl`. If your values
  file sets one of these URLs, it still wins, and it can use the same
  template expressions. A value that contains a literal `{{` now has to be
  escaped.
- **Remote model fallback is off (#138).** `litellm.configMap.LOCAL_MODEL_FALLBACK_TO_REMOTE`
  is now `'false'`. Set it to `'true'` if you want guardrails to fall back to a
  hosted model when the local model is unavailable.
- **Hosted endpoints (#138).** PostHog and the hosted leaderboard and MCP
  scanner Supabase URLs are empty by default. Set them in your values file if
  you use those features.
- **OpenFGA store and model IDs (#138).** The chart no longer sets them in the
  `frontend` and `gateway-kong` ConfigMaps. Before upgrading, make sure
  `frontend-env-secret` has `FGA_STORE_ID` and `FGA_MODEL_ID`, and
  `gateway-env-secret` has `DECK_OPENFGA_STORE_ID` and
  `DECK_OPENFGA_AUTHORIZATION_MODEL_ID` (`utils/post-installation.sh` writes
  them; with External Secrets, put them in the secret store). If your values
  file sets these keys in a ConfigMap, remove them.
- **Telemetry and metering off (#146).** `ENKRYPT_GATEWAY_URL` is only used when
  `GR_MODELS_MODE` or `RT_MODELS_MODE` is `enkrypt_hosted`; if you use that
  mode, set it (and `ENKRYPT_METERING_ENABLED`, if you meter) in your values
  file. The chart doesn't restart pods when a ConfigMap changes, so after the
  upgrade run
  `kubectl rollout restart deployment/redteam-proxy deployment/<release>-litellm -n <namespace>`.
  Red team job pods pick up the change on their next run.
- **decK config in the chart (#134).** The release now owns the
  `gateway-kong-temp-config` ConfigMap, which a hook Job used to create. On an
  existing install, the upgrade fails with `invalid ownership metadata` unless
  you adopt the ConfigMap first (Helm 3.17 or later can use
  `helm upgrade --take-ownership` instead):

  ```bash
  kubectl -n <namespace> label cm gateway-kong-temp-config app.kubernetes.io/managed-by=Helm --overwrite
  kubectl -n <namespace> annotate cm gateway-kong-temp-config \
    meta.helm.sh/release-name=<release> meta.helm.sh/release-namespace=<namespace> --overwrite
  ```

  After the upgrade, delete the old hook objects, which Helm doesn't track:

  ```bash
  kubectl -n <namespace> delete job create-gateway-configmap --ignore-not-found
  kubectl -n <namespace> delete rolebinding gateway-configmap-binding --ignore-not-found
  kubectl -n <namespace> delete role gateway-configmap-role --ignore-not-found
  kubectl -n <namespace> delete serviceaccount gateway-configmap-sa --ignore-not-found
  ```

  Route changes now go in `gateway-kong/files/kong.yaml`.
- **OpenFGA (#135).** If your values file sets `openfga.serviceAccount.create`,
  `openfga.datastore.waitForMigrations` or `openfga.migrate.annotations`,
  remove those keys (or set them to the new defaults). Otherwise the old
  post-install hook stays and `helm install --wait` still hangs. The OpenFGA
  pods restart once on upgrade.
- **Fluent Bit (#136).** If your values file copies
  `gateway-kong.resources.fluentBit.limits.memory: "256Gi"`, change it to
  `256Mi` or remove it.
- **ConfigMaps are no longer hooks (#144).** The app ConfigMaps (`*-env-cm` and
  supabase `onprem`) were created by Helm hooks, so the release didn't own
  them. Helm refuses to take them over on upgrade (`exists and cannot be
  imported into the current release: invalid ownership metadata`). Before the
  first `helm upgrade` to this version, hand them to the release (set
  `RELEASE` and `NS` to your release name and namespace; ConfigMaps that
  don't exist are skipped). The loop also covers the #134
  `gateway-kong-temp-config`, so it replaces the adoption step above:

  ```sh
  RELEASE=enkryptai NS=enkryptai-stack
  for ns in "$NS" redteam-jobs; do
    for cm in compliance-scan-env-cm frontend-env-cm gateway-env-cm \
              gateway-migration-env-cm guardrails-env-cm leaderboard-client-env-cm \
              leaderboard-server-env-cm litellm-gateway-env-cm mcp-scanner-env-cm \
              redteam-proxy-env-cm secure-mcp-gateway-env-cm skill-scanner-env-cm onprem \
              gateway-kong-temp-config; do
      kubectl get configmap "$cm" -n "$ns" >/dev/null 2>&1 || continue
      kubectl label configmap "$cm" -n "$ns" app.kubernetes.io/managed-by=Helm --overwrite
      kubectl annotate configmap "$cm" -n "$ns" --overwrite \
        meta.helm.sh/release-name="$RELEASE" meta.helm.sh/release-namespace="$NS" \
        helm.sh/hook- helm.sh/hook-weight-
    done
  done
  ```

  `redteam-proxy-env-cm` also lives in every namespace listed in
  `redteam-proxy.configMapNamespaces` (default `enkryptai-stack` and
  `redteam-jobs`); add any other namespace you set there to the outer loop.
- **`utils/post-installation.sh` (F-6, #142).** The script now needs `jq` on the
  machine that runs it. Run it the same way as before; `--print-only` shows
  the IDs without changing anything.
- **Probes (#139).** The probes that are on today stay on. Three new probes
  are on by default: `guardrails-model` startup and readiness (the pod, the
  Service and `helm --wait` now wait until the model is serving, up to
  20 minutes on a cold start), and `gateway-kong` readiness (`kong health`).
  These roll the guardrails-model and gateway-kong pods once on upgrade. Every
  other new probe ships with `enabled: false`. To
  turn one on, set `<component>.<startup|liveness|readiness>Probe.enabled: true`
  (Supabase: `supabase.<component>.<type>Probe`, nginx-html:
  `supabase.customtemplate.<type>Probe`, gateway-kong sidecars:
  `gateway-kong.sync.<type>Probe` and `gateway-kong.fluentBit.<type>Probe`).
  Turning probes on rolls the pods once.
- **Probe values shape (#139).** Every probe block is rendered as-is when
  `enabled: true`, so any probe type (`httpGet`, `tcpSocket`, `exec`, `grpc`)
  and any field can be set. Probe blocks for the Supabase components now need
  `enabled: true`; values files that set a Supabase probe without it still
  work for the components where the chart default is set, but should add it.
  To switch a probe to another type in a values file, set the old handler to
  `null` (for example `httpGet: null`).
- **Kong tracing (#154).** Kong now creates traces for 3% of requests and
  the `opentelemetry` plugin sends them to `tempo.monitoring:4318`. The
  gateway pods don't restart on ConfigMap changes, so run
  `kubectl -n <namespace> rollout restart deploy/gateway-kong` after the
  upgrade. If the cluster has no Tempo at `tempo.monitoring`, Kong logs export
  errors for the sampled requests (requests themselves are not affected); turn
  tracing off with
  `gateway-kong.configMap.gatewayEnv.KONG_TRACING_INSTRUMENTATIONS: "off"`.
  To change the sampling, set
  `gateway-kong.configMap.gatewayEnv.KONG_TRACING_SAMPLING_RATE` (`"1.0"`
  traces every request).

### Added

- **enkryptai-stack (#147):** `litellm.serviceAccount` (`create`, `annotations`,
  `name`) for workload identity, for example an IRSA
  `eks.amazonaws.com/role-arn` annotation. `create: true` makes a
  ServiceAccount (named `<release>-litellm` unless `name` is set); `name` alone
  uses an existing one. `name` and `annotations` go through `tpl`. With the
  defaults the Deployment is unchanged and uses the namespace's default
  ServiceAccount.
- **enkryptai-stack:** a `startupProbe` for every workload, and the missing
  readiness and liveness probes (#139). Off by default, except the three
  marked *on*:

  | Workload | Probe |
  | -------- | ----- |
  | `guardrails-model` | router `GET /health` on 8080 (startup budget 20 min, for the model load); startup and readiness *on* |
  | `secure-mcp-gateway` | `tcpSocket` 8000 (the gateway has no health route) |
  | `gateway-kong` (gateway) | `kong health` (startup, readiness); readiness *on* |
  | `gateway-kong` (`fluent-bit`) | `GET /api/v1/health` on 2020 (startup, liveness; no readiness, so a log backend outage doesn't take Kong out of the Service) |
  | `gateway-kong` (`gateway-deck-sync`) | none by default (no port); values hooks only |
  | Supabase `auth`, `meta` | `GET /health` |
  | Supabase `rest` | `GET /` (readiness), `tcpSocket` 3000 (startup, liveness) |
  | Supabase `storage` | `GET /status` |
  | Supabase `kong` | `tcpSocket` 8000 |
  | Supabase `minio` | `GET /minio/health/live`, `/minio/health/ready` |
  | Supabase `studio` | `GET /api/profile` (startup, readiness) |
  | `nginx-html` | `tcpSocket` 80 |
  | `openfga` | the upstream chart's startup and liveness probes |
  | other subcharts | `startupProbe` on the existing health path |

### Fixed

- **enkryptai-stack:** `litellm` `GR_MULTIMODAL_SERVICE_URL` pointed at
  `enkryptai-guardrails-multimodal`, a Service that doesn't exist; it now
  points at `<release>-guardrails-multi-modal`. Multimodal guardrails didn't
  work with the default values.
- **enkryptai-stack:** `redteam-proxy` `RELAY_ENDPOINT` and `RELAY_REDIS_URL`
  pointed at `redteam-proxy.redteam-jobs` and `valkey.dev` (the hosted
  layout); they now use the release namespace.
- **enkryptai-stack:** the `frontend` and `gateway-kong` ConfigMaps
  hardcoded OpenFGA store and model IDs from another environment (and the two
  didn't even match). The ConfigMap is listed after the Secret in `envFrom`,
  so these IDs overrode the correct ones in `frontend-env-secret` and
  `gateway-env-secret`. They are removed; the IDs now come only from the
  Secrets.
- **enkryptai-stack:** the `litellm`, `guardrails` and `redteam-proxy`
  Service URLs (`*-litellm`, `*-guardrails-model`, `supabase-storage`,
  `valkey`) no longer assume the release is called `enkryptai` and runs in
  `enkryptai-stack`.
- **enkryptai-stack:** `helm install --wait` no longer hangs on OpenFGA. The
  `openfga-migrate` Job is now a `pre-install, pre-upgrade` hook (it was
  `post-install, post-upgrade, post-rollback, post-delete`), so it runs before
  the Deployment. `openfga.datastore.waitForMigrations` is `false` and
  `openfga.serviceAccount.create` is `false`: the `wait-for-migration` init
  container, the `openfga` ServiceAccount and the `openfga-job-status-reader`
  Role and RoleBinding are no longer rendered, and the `k8s-wait-for` image is
  no longer needed (#135).
- **enkryptai-stack:** the gateway-kong `fluent-bit` sidecar memory limit was
  `256Gi` (effectively no limit); it is now `256Mi`, next to its `64Mi`
  request. Fixed in both `values.yaml` and the `gateway-kong` subchart
  defaults (#136).
- **enkryptai-stack:** the app ConfigMaps (`compliance-scan`, `frontend`,
  `gateway-kong` (`gateway-env-cm`, `gateway-migration-env-cm`), `guardrails`,
  `leaderboard-client`, `leaderboard-server`, `litellm`, `mcp-scanner`,
  `redteam-proxy`, `secure-mcp-gateway`, `skill-scanner`, supabase `onprem`)
  were `pre-install,pre-upgrade` hooks with no delete policy. Helm deleted and
  recreated them on every upgrade, and `helm uninstall` left them behind
  because hook resources are not part of the release. They are now normal
  resources: Helm creates ConfigMaps before Deployments in the same release,
  and nothing that runs before them (pre-install hooks) reads them. Rendered
  output is unchanged apart from the two hook annotations (#144).
- **enkryptai-stack:** the Supabase `onprem` ConfigMap had
  `STUDIO_PG_META_URL: http://enkrytpai-supabase-meta:8080` and
  `SUPABASE_URL: http://enkrytpai-supabase-kong:8000` (misspelled release
  name, so neither host exists). They are now
  `http://{{ .Release.Name }}-supabase-meta:8080` and
  `http://{{ .Release.Name }}-supabase-kong:8000`, and the `onprem`
  ConfigMap values go through `tpl`. Studio is the only component that reads
  these keys, and while `supabase.kong.enabled` / `supabase.meta.enabled` are
  on (the default) it sets both in its own `env`, which wins, so nothing that
  runs changes. A `supabase.configMap` value that contains a literal `{{`
  now has to be escaped (#143).
- **enkryptai-stack:** `supabase.analytics.enabled: true` failed to render
  (`nil pointer evaluating interface {}.repository`): the analytics
  `init-db` container read `.Values.supabaseinitdb`, which only exists in the
  parent chart's values and isn't visible to the Supabase subchart. It now
  uses `supabase.postgresalpine`, the same `pg_isready` image as the `auth`
  and `storage` init containers. Its `echo "Database is ready"` was a second
  `sh -c` argument (so it became `$0` and never ran); it is now part of the
  script (#143).
- **utils:** `post-installation.sh` took the OpenFGA store and model IDs from
  the first `store_id` / `authorization_model_id` it found in the last 1000
  lines of the OpenFGA pod logs, with the release name hardcoded as
  `enkryptai`. Once the request logs had rotated it found nothing, and it
  could pick a store or model that wasn't the current one. It now reads the
  store (`EnkryptAI`, the one `openfga-sync` creates) and its latest
  authorization model from the OpenFGA API, through the Kubernetes API
  server's service proxy (`kubectl get --raw`; no port-forward or extra pod)
  (#142).
- **enkryptai-stack:** the `guardrails` subchart's default probes pointed at
  port 80; the container listens on 8000. (The stack's values set 8000, so
  installs with the stack defaults weren't affected.) (#139)
- **enkryptai-stack:** `litellm` and `guardrails-multi-modal` probe defaults had
  no `enabled` key; they now have `enabled: true` (#139).
- **enkryptai-stack:** `KONG_TRACING_INSTRUMENTATIONS` and
  `KONG_TRACING_SAMPLING_RATE` were only in `gateway-kong.configMap.migrationEnv`
  (listed twice), which feeds the migration init containers, so the gateway
  container never created spans. They are now in `configMap.gatewayEnv`
  (`all`, `0.03`, the apiaas prod values); the duplicate pair in
  `migrationEnv` is removed (#154).

### Changed

- **enkryptai-stack:** the Supabase `auth`, `kong`, `meta`, `minio`, `rest`,
  `storage` and `studio` pods read `DB_NAME`, `DB_USER`, `DB_USERNAME`,
  `GOTRUE_HOOK_CUSTOM_ACCESS_TOKEN_URI` and `NEXT_ANALYTICS_BACKEND_PROVIDER`
  from the `onprem` ConfigMap instead of the `onprem` Secret, and carry a
  `checksum/onprem` annotation so a change rolls them.
- **enkryptai-stack:** no data leaves the cluster by default:
  `LOCAL_MODEL_FALLBACK_TO_REMOTE: 'false'` in `litellm`;
  `NEXT_PUBLIC_POSTHOG_HOST`, `NEXT_PUBLIC_LEADERBOARD_SUPABASE_URL` and
  `NEXT_PUBLIC_MCP_SCANNER_SUPABASE_URL` empty in `frontend`;
  `NEXT_PUBLIC_POSTHOG_HOST` empty in `leaderboard-client`.
- **enkryptai-stack:** `redteam-proxy` sets `ANONYMIZED_TELEMETRY: "false"`, so
  browser-use in the proxy and red-team job pods no longer sends the task
  (target URL, attack prompt) to PostHog. In `litellm`,
  `ENKRYPT_METERING_ENABLED` is `'false'` and `ENKRYPT_GATEWAY_URL` is empty
  by default.
- **utils:** `post-installation.sh` sets the Secret keys with one merge patch
  (adds or replaces), leaves Secrets owned by an `ExternalSecret` alone and
  prints the IDs to put in the secret store instead, and has new options:
  `--service`, `--store-name`, `--print-only` and `--no-restart`. It fails
  with a clear message when there is no store yet (the `openfga-sync` Job
  hasn't run) or when several stores match (#142).
- **enkryptai-stack:** every probe template uses the same block
  (`with` + `enabled` + `toYaml (omit . "enabled")`), in our subcharts, the
  Supabase subchart and `nginx-html`. Before, several templates rendered only
  `httpGet` or `exec` and a fixed list of fields, and dropped the rest (#139).

## Unreleased: F-33 red team Workflow identity (`platform-stack`)

Merged to `main`, not published yet. The release PR adds the version bump, the
package and the `index.yaml` entry.

### Security

- **platform-stack:** red team Workflow pods ran as `redteam-jobs:default`,
  which two ClusterRoleBindings gave the cluster-wide `argo-events-role`
  (Secrets in every namespace, `pods/exec`, pod create), and its token was
  mounted in the job container, which never uses it (F-33). Workflows now run
  as a new `redteam-workflow` ServiceAccount with `automountServiceAccountToken:
  false`, bound only in `redteam-jobs` to `argo-events-role-workflow`; the
  executor reads its token from the `redteam-workflow.service-account-token`
  Secret, so only the `init` and `wait` containers get it. The
  `redteam-jobs-binding-events` and `redteam-jobs-binding-workflow`
  ClusterRoleBindings are removed.

## Unreleased — platform-core as its own release (`platform-stack`, `platform-core`)

Merged to `main`, not published yet. `charts/platform/Chart.yaml` is already
at 1.3.0; `platform-core` changed but is still versioned 1.3.0 (the published
version), so the release PR bumps it to 1.3.1, points `platform-stack` at it,
and updates the version table above.

| Chart            | Version         | Pull request |
| ---------------- | --------------- | ------------ |
| `platform-stack` | 1.2.2 → 1.3.0   | [#133](https://github.com/enkryptai/helm-charts/pull/133) |
| `platform-core`  | 1.3.0 → 1.3.1   | [#133](https://github.com/enkryptai/helm-charts/pull/133) |

### Upgrading from 1.2.x

Existing installs keep one release. Before `helm upgrade` of an existing
`platform-stack` release:

1. **Set `platform-core.enabled: true`** in your platform values. The default
   is now `false` (platform-core as its own release). Upgrading an existing
   release with `false` fails with "release ... still owns platform-core",
   because it would delete the operators, their CRDs and the OpenSearch
   cluster.
2. Coming from 1.2.1, also do the 1.2.2 steps below (Argo CRD adoption, Kong
   password, GPU flag, backup values).

With `platform-core.enabled: true` the release renders the same resources as
1.2.2, apart from the changes listed here. Moving an existing install to
separate releases is not supported yet; reinstall to change layout.

### Added

- **platform-stack:** `platform-core.enabled` (default `false`). With `false`,
  platform-core is installed first as its own release
  (`helm install platform-core enkryptai/platform-core`), and the CNPG
  Clusters, the OpenSearch cluster, its roles, tenants, role bindings, index
  templates and ISM policies, the Argo EventBus, EventSource and Sensor, the
  NATS Streams and the `opensearch-cred` and `openfga-env-secret` Secrets are
  normal resources: `helm upgrade` now updates them and no longer deletes and
  recreates the post-upgrade ones. With `true` they stay hooks, as in 1.2.x.
  The migration ConfigMap and the three Jobs stay hooks in both layouts.
- **platform-stack:** upgrade guard (`templates/platform-core-guard.yaml`):
  stops an upgrade with `platform-core.enabled: false` when this release
  still owns the platform-core CRDs.
- **platform-stack:** `helm.sh/resource-policy: keep` on `supabase-cluster`,
  `cluster-openfga` and `enkryptai-opensearch`, so `helm uninstall` leaves
  the data in place. `utils/uninstall.sh` deletes them explicitly.
- **platform-core:** `helm.sh/resource-policy: keep` on the OpenSearch
  operator CRDs, as the CNPG CRDs already have. Deleting these CRDs deleted
  the OpenSearch cluster and its data. The CRDs are now rendered from
  `files/opensearch-operator-crds/` (unchanged from opensearch-operator
  2.8.0) with `opensearch-operator.installCRDs: false`.

### Changed

- **platform-core:** default values now match the `platform-core:` block of
  platform-stack (image tags, `gpu-operator.enabled: false`,
  `argo-workflows.crds.full: false`, `singleNamespace: false`, Argo
  retention policy, `argo-events.namespaceOverride`), so a separate
  platform-core release renders the same resources as the bundled one.
- **utils/uninstall.sh:** uninstalls `enkryptai`, then `platform`, deletes the
  data clusters while the operators still run, then uninstalls
  `platform-core`. Label selectors include `platform-core`.
- **README:** install order platform-core → platform → enkryptai, and how to
  build the platform-core values file.

### Removed

- **platform-stack:** the second copy of the 3 OpenSearch tenants and 5 role
  bindings at the end of `roles-all.yaml` (also in `tenant.yaml` and
  `role-binding.yaml`). As normal resources the duplicates would fail the
  install.

### Notes

- **Helm 4** applies server-side. The OpenSearch operator co-owns
  `spec.nodePools` of the OpenSearch cluster, so the first `helm upgrade` of
  `platform` after an install with separate releases needs
  `--force-conflicts`.

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
