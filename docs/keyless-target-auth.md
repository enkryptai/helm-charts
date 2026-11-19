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
- Kong signs an owner assertion for each red team request on a role target, and the red team service verifies it. The installer's secret generator creates the signing key and the public-key list: `ENKRYPT_OWNER_ASSERTION_KEY` and `ENKRYPT_OWNER_ASSERTION_KEY_ID` in `gateway-env-secret`, and `OWNER_ASSERTION_PUBLIC_KEYS` in `redteam-proxy-env-secret` in both namespaces. If you load these secrets from an external store, add the three keys there.
- The Kong plugin fields that read the key need a gateway image that supports them. See the release notes.
