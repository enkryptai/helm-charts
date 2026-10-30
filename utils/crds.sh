#!/usr/bin/env bash
# Operator CRDs as their own install step, before platform-core (README "CRDs as a separate step").
# Usage: crds.sh build <dir> | adopt | apply <dir>
set -euo pipefail

CHART_DIR="$(cd "$(dirname "$0")/../charts/platform-core" && pwd)"
GROUPS_RE='argoproj.io|postgresql.cnpg.io|opensearch.opster.io|jetstream.nats.io|nfd.k8s-sigs.io|nvidia.com'
VERSION_KEY="enkrypt.ai/crd-bundle-version"

stack_crds() {
  kubectl get crd -o name | { grep -E "\.(${GROUPS_RE})$" || true; } | sed 's|.*/||'
}

# One file per CRD, rendered from platform-core with every CRD source on, so the bundle matches the chart's operators.
build() {
  local out=${1:?output directory} version
  version=$(yq '.version' "$CHART_DIR/Chart.yaml")
  mkdir -p "$out"
  ls "$CHART_DIR"/charts/*.tgz >/dev/null 2>&1 || { echo "No subcharts in $CHART_DIR/charts; run helm dependency update first"; return 1; }
  helm template platform-core "$CHART_DIR" --include-crds --set gpu-operator.enabled=true \
    | yq e "select(.kind == \"CustomResourceDefinition\" and (.metadata.name | test(\"\\\\.(${GROUPS_RE})\$\")))" \
    | yq -s "\"$out/\" + .metadata.name + \".yaml\"" -
  for f in "$out"/*.yaml; do
    yq -i ".metadata.annotations.\"$VERSION_KEY\" = \"$version\"
      | .metadata.annotations.\"helm.sh/resource-policy\" = \"keep\"
      | del(.metadata.annotations.\"meta.helm.sh/release-name\", .metadata.annotations.\"meta.helm.sh/release-namespace\",
            .metadata.labels.\"app.kubernetes.io/managed-by\")" "$f"
  done
  echo "Wrote $(ls "$out" | wc -l | tr -d ' ') CRDs for platform-core $version to $out"
}

# Existing installs only, before the first upgrade with values-external-crds.yaml: Helm deletes a CRD that leaves a release unless the live object has keep.
adopt() {
  local crd n=0
  for crd in $(stack_crds); do
    kubectl annotate crd "$crd" helm.sh/resource-policy=keep --overwrite >/dev/null
    n=$((n + 1))
  done
  echo "Annotated $n CRDs with helm.sh/resource-policy=keep"
}

# Refuses the whole bundle when any live CRD came from a newer bundle, so a re-apply never downgrades.
apply() {
  local dir=${1:?bundle directory} f name live want refuse=0
  for f in "$dir"/*.yaml; do
    name=$(yq '.metadata.name' "$f")
    want=$(yq ".metadata.annotations.\"$VERSION_KEY\"" "$f")
    live=$(kubectl get crd "$name" -o jsonpath="{.metadata.annotations.${VERSION_KEY//./\\.}}" 2>/dev/null || true)
    if [[ -n $live && $live != "$want" && $(printf '%s\n%s\n' "$live" "$want" | sort -V | tail -1) == "$live" ]]; then
      echo "Refusing: $name is at $live, this bundle is $want"
      refuse=1
    fi
  done
  if [[ $refuse == 1 ]]; then
    echo "Nothing applied."
    return 1
  fi
  # --force-conflicts takes the fields Helm or the Argo CRD Job set on an existing install.
  kubectl apply --server-side --field-manager=enkryptai-crds --force-conflicts -f "$dir"
}

case "${1:-}" in
  build) build "${2:-}" ;;
  adopt) adopt ;;
  apply) apply "${2:-}" ;;
  *) echo "Usage: $0 build <dir> | adopt | apply <dir>"; exit 1 ;;
esac
