#!/bin/sh

#######################################################################
# OpenFGA Post-Installation Setup Script (POSIX sh)
#
# Run after the enkryptai-stack install, once the openfga-sync Job has
# succeeded:
# - Reads the store ID and the latest authorization model ID from the
#   OpenFGA API (the same store and model the openfga-sync Job wrote)
# - Writes them to gateway-env-secret and frontend-env-secret
# - Restarts frontend and gateway-kong so they pick up the IDs
#
# The API is reached through the Kubernetes API server's service proxy
# (kubectl get --raw), so no port-forward, curl or extra pod is needed.
#
# Requires: kubectl, jq, base64
# Supports: Linux, macOS, Windows (Git Bash/WSL)
#######################################################################

set -e

# Defaults
NAMESPACE="enkryptai-stack"
OPENFGA_SERVICE="openfga"
OPENFGA_PORT="http"
STORE_NAME="EnkryptAI"
PRINT_ONLY="false"
RESTART="true"
SCRIPT_NAME=$(basename "$0")

# Logging
log_info()    { echo "[INFO] $1"; }
log_success() { echo "[SUCCESS] $1"; }
log_warning() { echo "[WARNING] $1"; }
log_error()   { echo "[ERROR] $1" >&2; }

print_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Options:
    -n, --namespace NAMESPACE    Kubernetes namespace (default: enkryptai-stack)
    -s, --service NAME           OpenFGA Service name (default: openfga)
        --store-name NAME        OpenFGA store name (default: EnkryptAI, as created by openfga-sync)
        --print-only             Print the IDs and exit; change nothing
        --no-restart             Update the Secrets but do not restart frontend and gateway-kong
    -h, --help                   Display this help message
EOF
}

# Parse args
while [ $# -gt 0 ]; do
    case "$1" in
        -n|--namespace) NAMESPACE="$2"; shift 2;;
        -s|--service) OPENFGA_SERVICE="$2"; shift 2;;
        --store-name) STORE_NAME="$2"; shift 2;;
        --print-only) PRINT_ONLY="true"; shift;;
        --no-restart) RESTART="false"; shift;;
        -h|--help) print_usage; exit 0;;
        *) log_error "Unknown option: $1"; print_usage; exit 1;;
    esac
done

# Prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    command -v kubectl >/dev/null 2>&1 || { log_error "kubectl not found"; exit 1; }
    command -v jq >/dev/null 2>&1 || { log_error "jq not found (https://jqlang.org/download/)"; exit 1; }
    command -v base64 >/dev/null 2>&1 || { log_error "base64 not found"; exit 1; }
    kubectl cluster-info >/dev/null 2>&1 || { log_error "Cannot connect to cluster"; exit 1; }
    kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || { log_error "Namespace '$NAMESPACE' missing"; exit 1; }
    kubectl get service "$OPENFGA_SERVICE" -n "$NAMESPACE" >/dev/null 2>&1 || {
        log_error "Service '$OPENFGA_SERVICE' not found in '$NAMESPACE' (set it with --service)"; exit 1; }
    log_success "Prerequisites check passed"
}

# GET a path on the OpenFGA HTTP API, through the API server's service proxy
openfga_get() {
    kubectl get --raw "/api/v1/namespaces/$NAMESPACE/services/$OPENFGA_SERVICE:$OPENFGA_PORT/proxy$1"
}

# Step 1: Retrieve IDs from the OpenFGA API
retrieve_ids() {
    log_info "Reading the store and authorization model from the OpenFGA API..."

    stores_json=$(openfga_get "/stores?page_size=100") || {
        log_error "Could not call the OpenFGA API (GET /stores). Is the openfga pod Ready?"; exit 1; }

    store_count=$(echo "$stores_json" | jq '.stores | length')
    named_count=$(echo "$stores_json" | jq --arg n "$STORE_NAME" '[.stores[] | select(.name == $n)] | length')

    if [ "$named_count" -eq 1 ]; then
        STORE_ID=$(echo "$stores_json" | jq -r --arg n "$STORE_NAME" '.stores[] | select(.name == $n) | .id')
    elif [ "$named_count" -eq 0 ] && [ "$store_count" -eq 1 ]; then
        # openfga-sync uses the first store it finds, whatever its name
        STORE_ID=$(echo "$stores_json" | jq -r '.stores[0].id')
        log_warning "No store named '$STORE_NAME'; using the only store: $(echo "$stores_json" | jq -r '.stores[0].name')"
    elif [ "$store_count" -eq 0 ]; then
        log_error "OpenFGA has no store yet. Check that the openfga-sync Job succeeded:"
        log_error "  kubectl logs job/openfga-sync -n $NAMESPACE"
        exit 1
    else
        log_error "Cannot pick a store: $named_count named '$STORE_NAME', $store_count in total:"
        echo "$stores_json" | jq -r '.stores[] | "  \(.id)  \(.name)  created \(.created_at)"' >&2
        log_error "Pass the right name with --store-name."
        exit 1
    fi

    # OpenFGA lists models newest first; openfga-sync writes the latest one
    models_json=$(openfga_get "/stores/$STORE_ID/authorization-models?page_size=1") || {
        log_error "Could not call the OpenFGA API (GET /stores/$STORE_ID/authorization-models)"; exit 1; }
    AUTH_MODEL_ID=$(echo "$models_json" | jq -r '.authorization_models[0].id // empty')

    [ -z "$STORE_ID" ] && { log_error "Store ID not found"; exit 1; }
    [ -z "$AUTH_MODEL_ID" ] && {
        log_error "Store $STORE_ID has no authorization model. Check the openfga-sync Job:"
        log_error "  kubectl logs job/openfga-sync -n $NAMESPACE"
        exit 1; }

    log_success "Retrieved IDs: store_id=$STORE_ID, authorization_model_id=$AUTH_MODEL_ID"
}

# Base64 encode (no newlines)
base64_encode() {
    printf '%s' "$1" | base64 | tr -d '\n'
}

# Write two keys to a Secret (adds or replaces them). A Secret owned by an
# ExternalSecret is left alone: the operator would revert the change, so the
# IDs have to go into the secret store instead.
patch_secret() {
    secret="$1"; store_key="$2"; model_key="$3"
    if ! kubectl get secret "$secret" -n "$NAMESPACE" >/dev/null 2>&1; then
        log_warning "$secret not found; create it with $store_key=$STORE_ID and $model_key=$AUTH_MODEL_ID"
        return 0
    fi
    owner=$(kubectl get secret "$secret" -n "$NAMESPACE" -o jsonpath='{.metadata.ownerReferences[*].kind}')
    case " $owner " in
        *" ExternalSecret "*)
            log_warning "$secret is managed by an ExternalSecret; not patched. Put these in the secret store:"
            echo "    $store_key=$STORE_ID"
            echo "    $model_key=$AUTH_MODEL_ID"
            return 0;;
    esac
    kubectl patch secret "$secret" -n "$NAMESPACE" --type=merge \
        -p '{"data":{"'"$store_key"'":"'"$(base64_encode "$STORE_ID")"'","'"$model_key"'":"'"$(base64_encode "$AUTH_MODEL_ID")"'"}}' >/dev/null
    log_success "Updated $secret"
}

# Step 2: Update secrets
update_secrets() {
    log_info "Updating Kubernetes secrets..."
    patch_secret gateway-env-secret DECK_OPENFGA_STORE_ID DECK_OPENFGA_AUTHORIZATION_MODEL_ID
    patch_secret frontend-env-secret FGA_STORE_ID FGA_MODEL_ID
}

# Step 3: Restart deployments
restart_deployments() {
    log_info "Restarting deployments..."
    kubectl rollout restart deployment frontend -n "$NAMESPACE" >/dev/null 2>&1 && log_success "Frontend restarted" || log_warning "Frontend not found"
    kubectl rollout restart deployment gateway-kong -n "$NAMESPACE" >/dev/null 2>&1 && log_success "Gateway-kong restarted" || log_warning "Gateway-kong not found"
}

# Wait for deployments
wait_for_deployments() {
    log_info "Waiting for deployments..."
    kubectl rollout status deployment frontend -n "$NAMESPACE" --timeout=300s || log_warning "Frontend not ready"
    kubectl rollout status deployment gateway-kong -n "$NAMESPACE" --timeout=300s || log_warning "Gateway-kong not ready"
    log_success "Deployments check complete"
}

# Main
main() {
    log_info "Starting OpenFGA Post-Installation Setup (Namespace: $NAMESPACE)"
    check_prerequisites
    retrieve_ids
    if [ "$PRINT_ONLY" = "true" ]; then
        echo "FGA_STORE_ID=$STORE_ID"
        echo "FGA_MODEL_ID=$AUTH_MODEL_ID"
        exit 0
    fi
    update_secrets
    if [ "$RESTART" = "true" ]; then
        restart_deployments
        wait_for_deployments
    else
        log_info "Skipping restart (--no-restart); restart frontend and gateway-kong to pick up the IDs"
    fi
    log_success "Post-installation setup completed!"
    echo "Monitor pods with: kubectl get pods -n $NAMESPACE -w"
}

main
