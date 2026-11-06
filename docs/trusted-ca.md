# Trusting a private CA

Use this when the services that EnkryptAI calls (sign-in providers, S3, model endpoints, the targets of a red team run) present certificates signed by a private CA.

## Steps

1. Build one PEM bundle that holds the public CAs and your private CA. The chart sets `SSL_CERT_FILE`, `REQUESTS_CA_BUNDLE` and `AWS_CA_BUNDLE`, and each of these replaces the image's default trust store. A bundle with only the private CA breaks every call to a public endpoint.
2. Put the bundle in a ConfigMap, in each namespace that runs EnkryptAI pods: the `enkryptai-stack` release namespace and `redteam-jobs`. trust-manager can keep these copies in sync; a plain ConfigMap works too.

   ```sh
   kubectl -n enkryptai-stack create configmap customer-ca --from-file=ca.crt=bundle.pem
   kubectl -n redteam-jobs create configmap customer-ca --from-file=ca.crt=bundle.pem
   ```

3. Set the same value in the `enkryptai-stack` and `platform-stack` releases:

   ```yaml
   global:
     trustedCA:
       configMapName: customer-ca
       key: ca.crt   # the key that holds the bundle; ca.crt is the default
   ```

4. Restart the pods after a bundle change. The mounted file updates in place, but the processes read it at start.

## What the value changes

With `configMapName` empty, the render does not change. With it set:

- Each chart renders a ConfigMap `<release>-trusted-ca-env` with `NODE_EXTRA_CA_CERTS`, `SSL_CERT_FILE`, `REQUESTS_CA_BUNDLE` and `AWS_CA_BUNDLE`, all set to `/etc/enkryptai/trusted-ca/ca.crt`. `platform-stack` renders its copy in `redteam-jobs`.
- Every container of every EnkryptAI Deployment and StatefulSet in `enkryptai-stack` (Supabase included), and the red team Workflow container in the `platform-stack` Sensor, reads that ConfigMap first in `envFrom` and mounts the bundle read-only at `/etc/enkryptai/trusted-ca`. A component's own `env` or later `envFrom` entry still wins.

The helpers are in `charts/enkryptai-stack/templates/_trusted-ca.tpl` and `charts/platform/templates/_trusted-ca.tpl`. They use only `envFrom`, `volumeMounts` and `volumes`; the outbound proxy values use `env`.

## Not covered

- Init containers that only wait for the database or run migrations, Jobs and helm test pods. They call in-cluster services only.
- Init containers given as raw values, such as `secure-mcp-gateway.initContainers`. Add the mount and the variables to those values yourself.
- Kong (`gateway-kong` and Supabase Kong) gets the variables, but Kong reads its upstream trust store from `KONG_LUA_SSL_TRUSTED_CERTIFICATE`. Set that too if Kong calls a TLS upstream signed by the private CA.
- Upstream charts (OpenFGA, CloudNativePG, OpenSearch, Argo, NATS, Valkey, GPU operator, Traefik, OpenTelemetry). They call in-cluster services only, except as their own values configure (for example CloudNativePG backups take `endpointCA`).
