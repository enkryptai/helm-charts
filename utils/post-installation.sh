#!/bin/sh

#######################################################################
# OpenFGA Post-Installation Setup Script (POSIX-sh version)
#
# Automates configuration of OpenFGA after Helm chart installation:
# - Retrieves store_id and authorization_model_id
# - Updates Kubernetes secrets
# - Restarts deployments
#
# Supports: Linux, macOS, Windows (Git Bash/WSL)
#######################################################################

set -e

# Defaults
NAMESPACE="enkryptai-stack"
SCRIPT_NAME=$(basename "$0")
OS_TYPE=""

# Logging
log_info()    { echo "[INFO] $1"; }
log_success() { echo "[SUCCESS] $1"; }
log_warning() { echo "[WARNING] $1"; }
log_error()   { echo "[ERROR] $1"; }

print_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Options:
    -n, --namespace NAMESPACE    Kubernetes namespace (default: enkryptai-stack)
    -h, --help                   Display this help message
EOF
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)   OS_TYPE="Linux"; log_success "Detected: Linux";;
        Darwin*)  OS_TYPE="macOS"; log_success "Detected: macOS";;
        CYGWIN*|MINGW*|MSYS*) OS_TYPE="Windows"; log_success "Detected: Windows";;
        *) OS_TYPE="Linux"; log_warning "Unknown OS, defaulting to Linux";;
    esac
}

# Extract pattern
extract_pattern() {
    input="$1"
    pattern="$2"
    case "$OS_TYPE" in
        Linux|Windows) echo "$input" | grep -o "$pattern" | head -n 1 || true;;
        macOS) echo "$input" | grep -oE "$pattern" | head -n 1 || true;;
    esac
}

# Extract value
extract_value() {
    echo "$1" | cut -d'"' -f3
}

# Base64 encode (no newlines)
base64_encode() {
    input="$1"
    echo -n "$input" | base64 | tr -d '\n'
}

# Parse args
while [ $# -gt 0 ]; do
    case "$1" in
        -n|--namespace) NAMESPACE="$2"; shift 2;;
        -h|--help) print_usage; exit 0;;
        *) log_error "Unknown option: $1"; print_usage; exit 1;;
    esac
done

# Prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    command -v kubectl >/dev/null 2>&1 || { log_error "kubectl not found"; exit 1; }
    kubectl cluster-info >/dev/null 2>&1 || { log_error "Cannot connect to cluster"; exit 1; }
    kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || { log_error "Namespace '$NAMESPACE' missing"; exit 1; }
    command -v grep >/dev/null 2>&1 || { log_error "grep not found"; exit 1; }
    command -v base64 >/dev/null 2>&1 || { log_error "base64 not found"; exit 1; }
    log_success "Prerequisites check passed"
}

# Step 1: Retrieve IDs
retrieve_ids() {
    log_info "Retrieving store_id and authorization_model_id..."
    log_output=$(kubectl logs -l app.kubernetes.io/name=openfga,app.kubernetes.io/instance=enkryptai -n "$NAMESPACE" --tail=1000 2>/dev/null || true)
    [ -z "$log_output" ] && { log_error "No logs found"; exit 1; }

    store_pattern=$(extract_pattern "$log_output" 'store_id":"[^"]*')
    auth_pattern=$(extract_pattern "$log_output" 'authorization_model_id":"[^"]*')

    if [ -z "$store_pattern" ] || [ -z "$auth_pattern" ]; then
        STORE_ID=$(echo "$log_output" | sed -n 's/.*"store_id":"\([^"]*\)".*/\1/p' | head -n 1)
        AUTH_MODEL_ID=$(echo "$log_output" | sed -n 's/.*"authorization_model_id":"\([^"]*\)".*/\1/p' | head -n 1)
    else
        STORE_ID=$(extract_value "$store_pattern")
        AUTH_MODEL_ID=$(extract_value "$auth_pattern")
    fi

    [ -z "$STORE_ID" ] && { log_error "Store ID not found"; exit 1; }
    [ -z "$AUTH_MODEL_ID" ] && { log_error "Auth Model ID not found"; exit 1; }

    log_success "Retrieved IDs: store_id=$STORE_ID, authorization_model_id=$AUTH_MODEL_ID"
}

# Step 2: Update secrets
update_secrets() {
    log_info "Updating Kubernetes secrets..."
    store_id_b64=$(base64_encode "$STORE_ID")
    auth_model_id_b64=$(base64_encode "$AUTH_MODEL_ID")

    # gateway-env-secret
    if kubectl get secret gateway-env-secret -n "$NAMESPACE" >/dev/null 2>&1; then
        kubectl patch secret gateway-env-secret -n "$NAMESPACE" --type='json' -p='[
            {"op": "replace", "path": "/data/DECK_OPENFGA_STORE_ID", "value": "'"$store_id_b64"'"},
            {"op": "replace", "path": "/data/DECK_OPENFGA_AUTHORIZATION_MODEL_ID", "value": "'"$auth_model_id_b64"'"}
        ]' || {
            kubectl patch secret gateway-env-secret -n "$NAMESPACE" --type='json' -p='[
                {"op": "add", "path": "/data/DECK_OPENFGA_STORE_ID", "value": "'"$store_id_b64"'"},
                {"op": "add", "path": "/data/DECK_OPENFGA_AUTHORIZATION_MODEL_ID", "value": "'"$auth_model_id_b64"'"}
            ]'
        }
        log_success "Updated gateway-env-secret"
    else
        log_warning "gateway-env-secret not found"
    fi

    # frontend-env-secret
    if kubectl get secret frontend-env-secret -n "$NAMESPACE" >/dev/null 2>&1; then
        kubectl patch secret frontend-env-secret -n "$NAMESPACE" --type='json' -p='[
            {"op": "replace", "path": "/data/FGA_STORE_ID", "value": "'"$store_id_b64"'"},
            {"op": "replace", "path": "/data/FGA_MODEL_ID", "value": "'"$auth_model_id_b64"'"}
        ]' || {
            kubectl patch secret frontend-env-secret -n "$NAMESPACE" --type='json' -p='[
                {"op": "add", "path": "/data/FGA_STORE_ID", "value": "'"$store_id_b64"'"},
                {"op": "add", "path": "/data/FGA_MODEL_ID", "value": "'"$auth_model_id_b64"'"}
            ]'
        }
        log_success "Updated frontend-env-secret"
    else
        log_warning "frontend-env-secret not found"
    fi
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
    detect_os
    check_prerequisites
    retrieve_ids
    update_secrets
    restart_deployments
    wait_for_deployments
    log_success "Post-installation setup completed!"
    echo "Monitor pods with: kubectl get pods -n $NAMESPACE -w"
}

main
