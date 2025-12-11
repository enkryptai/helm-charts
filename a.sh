# !/bin/bash
helm uninstall platform -n enkryptai-stack
helm uninstall enkryptai-stack -n enkryptai-stack

kubectl get crds -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -vE '\.gatekeeper\.sh$' | xargs -r -I{} kubectl patch crd {} --type='json' -p='[{"op": "remove", "path": "/metadata/finalizers"}]'

kubectl get crds -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -vE '\.gatekeeper\.sh$' | xargs -r kubectl delete crd

kubectl delete pvc --all --all-namespaces
