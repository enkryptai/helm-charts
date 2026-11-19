# Keyless red team targets (AWS role)

Use this when red team targets on AWS (for example Bedrock) must use an IAM role that the customer owns, not access keys. EnkryptAI runs as one IAM role of your own, the red team role, and assumes the customer's role from it. The customer's role trusts the red team role and requires the tenant external ID that the dashboard shows.

This works on EKS only, through IRSA. Support for AKS and other clusters is not decided yet. Until then, leave the value empty there.

## Steps

1. Create the red team role in the AWS account of the EKS cluster.
   - Trust: the cluster's OIDC issuer, for two service accounts only: `system:serviceaccount:redteam-jobs:redteam-workflow` and `system:serviceaccount:<enkryptai-stack namespace>:redteam-proxy`.
   - Permission: only `sts:AssumeRole` on the customers' roles. The pods call targets with the customer's role.

   ```json
   {
     "Effect": "Allow",
     "Principal": { "Federated": "arn:aws:iam::<account>:oidc-provider/<issuer host and path>" },
     "Action": "sts:AssumeRoleWithWebIdentity",
     "Condition": {
       "StringEquals": {
         "<issuer host and path>:aud": "sts.amazonaws.com",
         "<issuer host and path>:sub": [
           "system:serviceaccount:redteam-jobs:redteam-workflow",
           "system:serviceaccount:enkryptai-stack:redteam-proxy"
         ]
       }
     }
   }
   ```

2. Put the role ARN in one shared values file, `values/values-redteam-role.yaml`, with only this key:

   ```yaml
   global:
     redteam:
       awsRoleArn: arn:aws:iam::<account>:role/<red team role>
   ```

3. Pass that file to both releases, after each release's own values file:

   ```sh
   helm upgrade --install platform enkryptai/platform-stack -n enkryptai-stack -f ./values/platform.yaml -f ./values/values-redteam-role.yaml --timeout 15m
   helm upgrade --install enkryptai enkryptai/enkryptai-stack -n enkryptai-stack -f ./values/enkryptai-stack.yaml -f ./values/values-redteam-role.yaml --timeout 15m
   ```

The two releases must have the same value. The two charts install separately, and Helm cannot share a value between releases. One file for both prevents a mismatch: with different values, the dashboard shows customers a role that the red team pods do not run as, and the customer's trust policy refuses the runs. Setting the key in each release's own values file also works, but then nothing keeps the two copies equal.

## What the value sets

With `awsRoleArn` empty, the render does not change. With it set:

- `platform-stack` annotates the `redteam-workflow` service account in `redteam-jobs` with `eks.amazonaws.com/role-arn`. Each red team run creates new pods, so the next run uses a new value.
- `enkryptai-stack` annotates the `redteam-proxy` service account (model-health and the playground) the same way. The proxy pod template gets a `checksum/aws-role-arn` annotation, so a new value restarts the proxy pods. EKS injects the role environment only when it creates a pod.
- `enkryptai-stack` sets `ENKRYPT_REDTEAM_AWS_ROLE_ARN` in `frontend-env-cm`. The dashboard shows this ARN in the trust policy that the customer copies. Empty hides that panel.

## Related settings

- `TARGET_AUTH_SINGLE_TENANT` in `redteam-proxy.configMap` defaults to `"true"`. In this mode, existing targets that use the pod's own AWS identity keep working after an upgrade, and a customer-set external ID is accepted. When you set `awsRoleArn`, the pod's own identity becomes the red team role, which can only assume roles. A target with no keys and no role then fails, so give it a role first.
- Kong signs an owner assertion for each red team request on a role target, and the red team service verifies it. The installer's secret generator creates the signing key and the public-key list: `ENKRYPT_OWNER_ASSERTION_KEY` and `ENKRYPT_OWNER_ASSERTION_KEY_ID` in `gateway-env-secret`, and `OWNER_ASSERTION_PUBLIC_KEYS` in `redteam-proxy-env-secret` in both namespaces. If you load these secrets from an external store, add the three keys there, and the external-ID key below.
- The Kong plugin fields that read the key need a gateway image that supports them. See the release notes.

## The external-ID key

Each tenant's external ID is `enkrypt-v1-` followed by 64 hex characters. Kong computes it as an HMAC-SHA256 of the tenant's owner ID with one key, `ENKRYPT_AWS_EXTERNAL_ID_KEY` in `gateway-env-secret`. The dashboard shows the value that Kong computed; the customer puts it in their role's trust policy as the `sts:ExternalId` condition. A keyed value cannot be guessed from an owner ID, which can be an email address, and it always fits the character set that AWS accepts.

The key is 32 random bytes written as 64 lowercase hex characters, the form `openssl rand -hex 32` prints. The installer's secret generator creates it once, on install or on the first upgrade that has this feature. Only Kong reads it: the gateway container takes all of `gateway-env-secret` through `envFrom`, and Kong reads the key as `{vault://env/enkrypt-aws-external-id-key}`. The frontend and the red team service read only named keys from that Secret, never this one.

**Back up the key; never regenerate it.** Every customer trust names a value that this key computed. A new key changes every tenant's external ID, and every customer role then refuses Enkrypt until its owner adds the new value. The generator never replaces an existing key, and `--rederive` cannot name it. If the key is lost and there is no backup, every customer must update their trust. If the key leaks, external IDs become computable, but Kong still sends only the caller's own value, so do not rotate it for that reason alone. If you must replace it, each customer first adds the new value to the `sts:ExternalId` condition (it takes a list), and only then do you change the key.

If you load `gateway-env-secret` from an external secret store, add `ENKRYPT_AWS_EXTERNAL_ID_KEY` to that store with the value from the cluster, and back up the store. With the signing key set and this key missing, Kong refuses every new request on a role target. Static-key targets and resumes of existing runs still work.

## What the customer sees in CloudTrail

On every new request that names a role (a red team run, the playground, and each model health check, which includes Test Configuration and the check on save), the red team service first calls AssumeRole with a wrong external ID of the same `enkrypt-v1-` shape. If that call succeeds, the role does not require the external ID, and the request fails with that reason. So each request leaves one denied AssumeRole in the customer's CloudTrail, followed by the AssumeRole that succeeds with the real value. The denied call is expected. A resumed run keeps its earlier result and makes no new check. The session name of the call that succeeds is `enkrypt-rt-` followed by 16 hex characters from the tenant's external ID; it does not show the owner ID.
