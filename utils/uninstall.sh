# #!/bin/bash

NAMESPACE="enkryptai-stack"

confirm() {
  read -p "$1 (yes/no): " choice
  case "$choice" in
    yes|YES|y|Y ) return 0 ;;
    * ) echo "Aborted."; return 1 ;;
  esac
}

cleanup_main_resources() {
  echo "Preview: Resources that will be deleted"

  local resources
  resources=$(kubectl get sts,deploy -n $NAMESPACE 2>/dev/null)
  local clusters
  clusters=$(kubectl get cluster -n $NAMESPACE 2>/dev/null || true)

  local combined="${resources}${clusters}"

  if [[ -z "$combined" || "$combined" == *"No resources found"* ]]; then
    echo "No StatefulSets, Deployments, or Clusters found in $NAMESPACE. Skipping."
    return
  fi

  [[ -n "$resources" ]] && echo "$resources"
  [[ -n "$clusters" ]] && echo "$clusters"

  echo ""
  confirm "Proceed with deleting above resources?" || return

  kubectl delete sts -n $NAMESPACE -l opster.io/opensearch-cluster=enkryptai-opensearch --ignore-not-found
  kubectl delete jobs -n $NAMESPACE -l 'app.kubernetes.io/instance in (enkryptai,platform)' --ignore-not-found
  kubectl delete cluster cluster-openfga,supabase-cluster -n $NAMESPACE --ignore-not-found
  kubectl delete deployment -n $NAMESPACE -l opensearch.cluster.dashboards=enkryptai-opensearch  --ignore-not-found
  echo "Resources deleted."
}

remove_argo_finalizers() {
  echo "Removing finalizers from Argo Events"

  local found=0

  local eventbuses
  eventbuses=$(kubectl get eventbus -n argo-events -o name 2>/dev/null)
  if [[ -n "$eventbuses" ]]; then
    found=1
    for i in $eventbuses; do
      kubectl patch $i -n argo-events -p '{"metadata":{"finalizers":[]}}' --type=merge
    done
  fi

  local sensors
  sensors=$(kubectl get sensors -n argo-events -o name 2>/dev/null)
  if [[ -n "$sensors" ]]; then
    found=1
    while IFS= read -r obj; do
      kubectl patch "$obj" -n argo-events -p '{"metadata":{"finalizers":[]}}' --type=merge
    done <<< "$sensors"
  fi

  local eventsources
  eventsources=$(kubectl get eventsources -n argo-events -o name 2>/dev/null)
  if [[ -n "$eventsources" ]]; then
    found=1
    for i in $eventsources; do
      kubectl patch $i -n argo-events -p '{"metadata":{"finalizers":[]}}' --type=merge
    done
  fi

  if [[ $found -eq 0 ]]; then
    echo "No Argo Events resources found. Skipping."
  else
    echo "Argo finalizers removed."
  fi
}

remove_opensearch_finalizers() {
  echo "Removing finalizers from OpenSearch resources"

  local found=0

  for r in opensearchclusters opensearchindextemplates opensearchroles opensearchtenants opensearchuserrolebindings; do
    local items
    items=$(kubectl get $r -n $NAMESPACE -o name 2>/dev/null)
    if [[ -n "$items" ]]; then
      found=1
      while IFS= read -r obj; do
        kubectl patch $obj -n $NAMESPACE -p '{"metadata":{"finalizers":[]}}' --type=merge
      done <<< "$items"
    fi
  done

  if [[ $found -eq 0 ]]; then
    echo "No OpenSearch resources found. Skipping."
  else
    echo "OpenSearch finalizers removed."
  fi
}

delete_crds() {
  local crd_list
  crd_list=$(kubectl get crd 2>/dev/null | grep -E 'postgresql\.cnpg\.io|argoproj\.io|opensearch\.opster\.io|jetstream\.nats\.io' || true)

  if [[ -z "$crd_list" ]]; then
    echo "No matching CRDs found. Skipping."
    return
  fi

  echo "CRDs to be deleted:"
  echo "$crd_list"
  echo ""
  confirm "Delete these CRDs?" || return

  for pattern in 'postgresql\.cnpg\.io' 'opensearch\.opster\.io' 'jetstream\.nats\.io' 'argoproj\.io'; do
    local names
    names=$(kubectl get crd 2>/dev/null | grep "$pattern" | awk '{print $1}')
    if [[ -n "$names" ]]; then
      echo "$names" | xargs kubectl delete crd --ignore-not-found
    fi
  done

  echo "CRDs deleted."
}

handle_pvc_cleanup() {
  local pvcs
  pvcs=$(kubectl get pvc -n $NAMESPACE 2>/dev/null)

  if [[ -z "$pvcs" || "$pvcs" == *"No resources found"* ]]; then
    echo "No PVCs found in $NAMESPACE. Skipping."
    return
  fi

  echo "PVCs in namespace: $NAMESPACE"
  echo "$pvcs"
  echo ""
  echo "WARNING: Deleting PVCs will permanently delete data."
  confirm "Do you want to delete these PVCs?" || return

  kubectl delete pvc -n $NAMESPACE -l 'app.kubernetes.io/instance in (enkryptai-stack,platform)' --ignore-not-found
  kubectl delete pvc -n $NAMESPACE -l opster.io/opensearch-cluster --ignore-not-found

  echo "PVCs deleted."
}

main() {
  echo "Starting EnkryptAI cleanup..."
  
  helm uninstall platform -n $NAMESPACE --ignore-not-found
  helm uninstall enkryptai-stack -n $NAMESPACE --ignore-not-found

  cleanup_main_resources
  remove_argo_finalizers
  remove_opensearch_finalizers
  delete_crds
  handle_pvc_cleanup

  echo ""
  echo "Cleanup complete."
}

main