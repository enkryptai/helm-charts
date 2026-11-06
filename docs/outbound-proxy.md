# Running behind an outbound proxy

Use this when the cluster reaches the internet (model APIs, sign-in providers, S3, red team targets) only through an HTTP proxy.

## Steps

1. Set the same block in the `enkryptai-stack` and `platform-stack` releases:

   ```yaml
   global:
     proxy:
       httpProxy: http://proxy.corp.example:3128
       httpsProxy: http://proxy.corp.example:3128
       noProxy: 10.0.0.0/16,172.20.0.0/16,.corp.example
   ```

2. In `noProxy`, add the pod CIDR, the Service CIDR, the node CIDR and any internal hosts that must not go through the proxy. Clients decide on the host name in the URL, so a call to an IP address (the API server address in `KUBERNETES_SERVICE_HOST`, a node address) matches only a CIDR entry, and only in clients that support CIDR entries (Go and Python `requests` do).
3. Set the upstream values in the table below for the components you turn on.

With `httpProxy` and `httpsProxy` both empty, the render does not change.

## What the block sets

Every container of every EnkryptAI Deployment and StatefulSet in `enkryptai-stack` (Supabase included) and the red team Workflow container in the `platform-stack` Sensor get, in front of their own `env` entries:

- `HTTP_PROXY`, `HTTPS_PROXY` and `NO_PROXY`, each also in lower case.
- `NODE_USE_ENV_PROXY=1`. Node.js reads the proxy variables only when this is set, from Node 22.21 and 24.0. Older Node versions ignore it and do not use the proxy.

A component's own `env` entry with the same name comes later in the list and wins.

`NO_PROXY` is the in-cluster default plus `noProxy`. The default is `localhost`, `127.0.0.1`, `::1`, `169.254.169.254`, `kubernetes.default`, `.svc`, `.cluster.local`, the release namespace, `.enkryptai-stack`, `.redteam-jobs`, `.argo-events`, and in `enkryptai-stack` the short Service names that components call without a domain (`frontend`, `gateway-kong`, `<release>-supabase-auth` and the others). A suffix entry such as `.svc` cannot match a short name, so a new Service that other components call by its short name goes into `enkryptai-stack.proxy.serviceHosts` in `charts/enkryptai-stack/templates/_outbound-proxy.tpl`.

The helpers use only `env`; the trusted-CA values (`docs/trusted-ca.md`) use `envFrom` and volumes.

## Not covered

- The Kong `gateway` container in `gateway-kong`. Kong does not read `HTTP_PROXY` for its upstream traffic; plugins that call out take their own proxy settings.
- The red team Sensor pod and the Argo executor containers in the Workflow pod. They call the Kubernetes API, and a proxy setting without the Service CIDR in `NO_PROXY` would send those calls to the proxy.
- Init containers that wait for the database or run migrations, Jobs and helm test pods. They call in-cluster services only.
- Init containers given as raw values, such as the `secure-mcp-gateway` config downloader, which calls S3. Add the variables to those values yourself.

## Upstream charts

Helm cannot copy `global.proxy` into another chart's values, so set these keys from the same answer. Charts not listed (Argo Events, the Argo Workflows controller and server, NATS, NACK, CloudNativePG, the OpenSearch operator, Valkey, OpenFGA, metrics-server) call in-cluster services only.

| Chart | Key | When it calls out |
|---|---|---|
| `platform-core` | `gpu-operator.driver.env` | The operator installs the driver (`driver.enabled: true`). |
| `platform-core` | `argo-workflows.executor.env` | The Workflow artifact repository is outside the cluster. Include the Service CIDR in `NO_PROXY`. |
| `platform-stack` | `otel.extraEnvs` | The collector exports outside the cluster. |
| `platform-stack` | `traefik.env` | Traefik requests certificates from an ACME server. |
