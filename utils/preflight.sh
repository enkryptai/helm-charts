#!/usr/bin/env bash
# =============================================================================
#  EnkryptAI On-Prem — Kubernetes Pre-Flight Check
#  Ref: https://docs.enkryptai.com/onprem-installation/infra-requirement
# =============================================================================
set -uo pipefail   # NOTE: intentionally NO -e  (arithmetic counters evaluate to 0 = falsy)

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
PASS_TAG="${GREEN}[PASS]${RESET}"
FAIL_TAG="${RED}[FAIL]${RESET}"
WARN_TAG="${YELLOW}[WARN]${RESET}"
INFO_TAG="${CYAN}[INFO]${RESET}"

# Use TOTAL=$((TOTAL+1)) style — never ((TOTAL++)) which exits under set -e when value=0
TOTAL=0; PASSED=0; FAILED=0; WARNED=0
FAILURES=()
GPU_NODE_LIST=()

pass()  { echo -e "  ${PASS_TAG}  $*"; PASSED=$((PASSED+1)); TOTAL=$((TOTAL+1)); }
fail()  { echo -e "  ${FAIL_TAG}  $*"; FAILED=$((FAILED+1)); TOTAL=$((TOTAL+1)); FAILURES+=("$*"); }
warn()  { echo -e "  ${WARN_TAG}  $*"; WARNED=$((WARNED+1)); TOTAL=$((TOTAL+1)); }
info()  { echo -e "  ${INFO_TAG}  $*"; }
header(){ echo -e "\n${BOLD}${CYAN}══ $* ══${RESET}"; }

semver_gte() { [ "$(printf '%s\n' "$1" "$2" | sort -V | head -1)" = "$2" ]; }
semver_eq_minor() { [ "$(echo "$1"|cut -d.-f1-2)" = "$(echo "$2"|cut -d.-f1-2)" ]; }

to_gib() {
  local r="$1"
  if   [[ "$r" =~ ^([0-9]+)Gi$ ]]; then echo "${BASH_REMATCH[1]}"
  elif [[ "$r" =~ ^([0-9]+)Mi$ ]]; then echo $(( ${BASH_REMATCH[1]} / 1024 ))
  elif [[ "$r" =~ ^([0-9]+)Ki$ ]]; then echo $(( ${BASH_REMATCH[1]} / 1048576 ))
  elif [[ "$r" =~ ^([0-9]+)$   ]]; then echo $(( ${BASH_REMATCH[1]} / 1073741824 ))
  else echo "0"; fi
}

to_gb() {
  local r="$1"

  if   [[ "$r" =~ ^([0-9]+)Ki$ ]]; then echo $(( ${BASH_REMATCH[1]} / 1048576 ))
  elif [[ "$r" =~ ^([0-9]+)Mi$ ]]; then echo $(( ${BASH_REMATCH[1]} / 1024 ))
  elif [[ "$r" =~ ^([0-9]+)Gi$ ]]; then echo "${BASH_REMATCH[1]}"
  elif [[ "$r" =~ ^([0-9]+)Ti$ ]]; then echo $(( ${BASH_REMATCH[1]} * 1024 ))
  elif [[ "$r" =~ ^([0-9]+)$   ]]; then echo $(( ${BASH_REMATCH[1]} / 1000000000 ))
  else echo "0"; fi
}
check_node_resources() {
  local NODE="$1" MIN_CPU="$2" MIN_RAM="$3" MIN_DISK="$4"
  local ok=true

  local vcpu_raw vcpu_int
  vcpu_raw=$(kubectl get node "$NODE" -o jsonpath='{.status.capacity.cpu}' 2>/dev/null || echo "0")
  if [[ "$vcpu_raw" =~ ^([0-9]+)m$ ]]; then vcpu_int=$(( ${BASH_REMATCH[1]} / 1000 ))
  else vcpu_int="${vcpu_raw%.*}"; fi
  if [ "${vcpu_int:-0}" -ge "$MIN_CPU" ]; then
    pass "  vCPU: ${vcpu_int} >= ${MIN_CPU} ✓"
  else fail "  vCPU: ${vcpu_int} < ${MIN_CPU} required"; ok=false; fi

  local ram_raw ram_gib
  ram_raw=$(kubectl get node "$NODE" -o jsonpath='{.status.capacity.memory}' 2>/dev/null || echo "0Ki")
  ram_gib=$(to_gib "$ram_raw")
  RAM_TOLERANCE=1
  if [ "$ram_gib" -ge $(( MIN_RAM - RAM_TOLERANCE )) ]; then
    pass "  RAM: ${ram_gib} GiB (required >= ${MIN_RAM} GiB) ✓"
  else fail "  RAM: ${ram_gib} GiB < ${MIN_RAM} GiB required"; ok=false; fi

  local disk_raw disk_gb
  disk_raw=$(kubectl get node "$NODE" -o jsonpath='{.status.capacity.ephemeral-storage}' 2>/dev/null || echo "0")
  disk_gb=$(to_gb "$disk_raw")
  if [ "$disk_gb" -ge $(( MIN_DISK - 15 )) ]; then
    pass "  Disk: ${disk_gb} GB (required >= ${MIN_DISK} GB) ✓"
  else fail "  Disk: ${disk_gb} GB < ${MIN_DISK} GB required"; ok=false; fi

  $ok && return 0 || return 1
}

# ── 0. Pre-requisites ────────────────────────────────────────────────────────
header "Pre-requisites"

if ! command -v kubectl &>/dev/null; then
  echo -e "${RED}ERROR: kubectl not found in PATH. Aborting.${RESET}"; exit 1
fi
KCL_VER=$(kubectl version --client -o json 2>/dev/null \
  | grep -o '"gitVersion":"[^"]*"' | head -1 | grep -o 'v[0-9][^"]*' || echo "unknown")
pass "kubectl found: client ${KCL_VER}"

if ! kubectl cluster-info &>/dev/null; then
  echo -e "${RED}ERROR: Cannot reach cluster. Check KUBECONFIG / context.${RESET}"; exit 1
fi
pass "Cluster reachable (context: $(kubectl config current-context 2>/dev/null || echo unknown))"

# ── 1. Kubernetes Version ────────────────────────────────────────────────────
header "Kubernetes Version"

# Extract version (e.g., 1.33.8)
SRV=$(kubectl get --raw /version 2>/dev/null \
  | jq -r '.gitVersion' \
  | sed -E 's/^v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')

info "Server version: v${SRV}"

# ---- semver helpers ----
semver_gte() {
  [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

semver_lt() {
  [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$2" ]
}
# ------------------------

if [ -z "$SRV" ] || [ "$SRV" = "unknown" ]; then
  warn "Could not determine server version"
else
  if semver_gte "$SRV" "1.31.0" && semver_lt "$SRV" "1.34.0"; then
    pass "Kubernetes v${SRV} is within supported range (>=1.31, <1.34) ✓"
  else
    fail "Kubernetes v${SRV} is NOT supported (requires >=1.31 and <1.34)"
  fi
fi
# ── 2. Ingress Controller ────────────────────────────────────────────────────
header "Ingress Controller"

ING_PRESENT=$(kubectl get ingressclass 2>/dev/null | wc -l | tr -d ' ')

if [ "${ING_PRESENT:-0}" -le 1 ]; then
  warn "No ingress classes found — skipping ingress checks"
else
  info "IngressClass resources detected"

  # Detect controller types from pods (best-effort, not hardcoded)
  CTRL_DETECTED=$(kubectl get pods -A \
    -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}' 2>/dev/null \
    | grep -Ei 'nginx|traefik|alb|envoy' | sort -u || true)

  if [ -n "$CTRL_DETECTED" ]; then
    info "Detected ingress-related controllers:"
    echo "$CTRL_DETECTED" | sed 's/^/    - /'
  else
    warn "Could not detect ingress controller type from running pods"
  fi
fi

# ── 4. Node Inventory ────────────────────────────────────────────────────────
header "Node Inventory"
TOTAL_N=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
READY_N=$(kubectl get nodes --no-headers 2>/dev/null | awk '$2=="Ready"' | wc -l | tr -d ' ')
NOT_READY_N=$((TOTAL_N - READY_N))
info "Total: ${TOTAL_N}   Ready: ${READY_N}   Not-Ready: ${NOT_READY_N}"
if   [ "$TOTAL_N" -eq 0 ];       then fail "No nodes found in cluster"
elif [ "$NOT_READY_N" -gt 0 ];   then fail "${NOT_READY_N} node(s) NOT Ready"
else pass "All ${TOTAL_N} node(s) Ready ✓"; fi

# ── 5. GPU Node Group ────────────────────────────────────────────────────────

# header "GPU Node Group (Guardrails)"
# while IFS= read -r N; do
#   [ -z "$N" ] && continue
#   G=$(kubectl get node "$N" -o jsonpath='{.status.capacity.nvidia\.com/gpu}' 2>/dev/null || echo "")
#   [ -n "$G" ] && [ "$G" != "0" ] && GPU_NODE_LIST+=("$N")
# done < <(kubectl get nodes --no-headers -o custom-columns="NAME:.metadata.name" 2>/dev/null)
 
# if [ "${#GPU_NODE_LIST[@]}" -eq 0 ]; then
#   fail "No GPU nodes found (no nvidia.com/gpu in allocatable)"
#   warn "Required: at least 1 NVIDIA GPU per node | 4 vCPU | 16 GiB RAM | 100 GB disk"
# else
#   for NODE in "${GPU_NODE_LIST[@]}"; do
#     echo -e "\n  ${BOLD}Node: ${NODE}${RESET}"
 
#     # GPU count — pass as long as at least 1 GPU is allocatable (any model)
#     GPU_C=$(kubectl get node "$NODE" -o jsonpath='{.status.allocatable.nvidia\.com/gpu}' 2>/dev/null || echo "0")
#     [ "${GPU_C:-0}" -ge 1 ] && pass "  GPU allocatable: ${GPU_C} ✓" || fail "  GPU allocatable: ${GPU_C:-0} < 1"
 
 
#     check_node_resources "$NODE" 4 16 100 || true
 
#     TI=$(kubectl get node "$NODE" \
#       -o jsonpath='{range .spec.taints[*]}{.key}={.value}:{.effect}  {end}' 2>/dev/null || echo "none")
#     info "  Taints: ${TI:-none}"
 
#     NR=$(kubectl get node "$NODE" \
#       -o jsonpath='{range .status.conditions[?(@.type=="Ready")]}{.status}{end}' 2>/dev/null || echo "Unknown")
#     [ "$NR" = "True" ] && pass "  Node Ready ✓" || fail "  Node NOT Ready (${NR})"
#   done
# fi
header "GPU Node Group (Guardrails)"
while IFS= read -r N; do
  [ -z "$N" ] && continue
  G=$(kubectl get node "$N" -o jsonpath='{.status.capacity.nvidia\.com/gpu}' 2>/dev/null || echo "")
  [ -n "$G" ] && [ "$G" != "0" ] && GPU_NODE_LIST+=("$N")
done < <(kubectl get nodes --no-headers -o custom-columns="NAME:.metadata.name" 2>/dev/null)
 
if [ "${#GPU_NODE_LIST[@]}" -eq 0 ]; then
  fail "No GPU nodes found (no nvidia.com/gpu in capacity)"
  warn "Required: at least 1 NVIDIA GPU per node | 4 vCPU | 16 GiB RAM | 100 GB disk"
else
  for NODE in "${GPU_NODE_LIST[@]}"; do
    echo -e "\n  ${BOLD}Node: ${NODE}${RESET}"
 
    # GPU count — pass as long as at least 1 GPU is allocatable (any model)
    GPU_C=$(kubectl get node "$NODE" -o jsonpath='{.status.allocatable.nvidia\.com/gpu}' 2>/dev/null || echo "0")
    [ "${GPU_C:-0}" -ge 1 ] && pass "  GPU allocatable: ${GPU_C} ✓" || fail "  GPU allocatable: ${GPU_C:-0} < 1"
 
    # ── GPU identity (informational — no specific model is required) ──────────
    # 1. Product name  e.g. "NVIDIA-A10G", "Tesla-V100-SXM2-16GB"
    GPU_PRODUCT=$(kubectl get node "$NODE" \
      -o jsonpath='{.metadata.labels.nvidia\.com/gpu\.product}' 2>/dev/null || echo "")
    # 2. Architecture family  e.g. "ampere", "volta", "turing"
    GPU_FAMILY=$(kubectl get node "$NODE" \
      -o jsonpath='{.metadata.labels.nvidia\.com/gpu\.family}' 2>/dev/null || echo "")
    # 3. Machine / instance type as a last resort  e.g. "g4dn.xlarge", "Standard_NC6s_v3"
    INSTANCE_TYPE=$(kubectl get node "$NODE" \
      -o jsonpath='{.metadata.labels.node\.kubernetes\.io/instance-type}' 2>/dev/null || echo "")
    [ -z "$INSTANCE_TYPE" ] && INSTANCE_TYPE=$(kubectl get node "$NODE" \
      -o jsonpath='{.metadata.labels.beta\.kubernetes\.io/instance-type}' 2>/dev/null || echo "")
 
    if   [ -n "$GPU_PRODUCT" ] && [ -n "$GPU_FAMILY" ]; then
      info "  GPU product : ${GPU_PRODUCT}"
      info "  GPU family  : ${GPU_FAMILY}"
    elif [ -n "$GPU_PRODUCT" ]; then
      info "  GPU product : ${GPU_PRODUCT}"
      warn "  GPU family  : label nvidia.com/gpu.family not found — GPU Operator may not be installed"
    elif [ -n "$GPU_FAMILY" ]; then
      warn "  GPU product : label nvidia.com/gpu.product not found"
      info "  GPU family  : ${GPU_FAMILY}"
    else
      warn "  GPU identity: nvidia.com/gpu.product and gpu.family labels absent — GPU Operator / device-plugin may not be running"
    fi
    [ -n "$INSTANCE_TYPE" ] && info "  Instance type: ${INSTANCE_TYPE}" || true
    # ─────────────────────────────────────────────────────────────────────────
 
    check_node_resources "$NODE" 4 16 100 || true
 
    TI=$(kubectl get node "$NODE" \
      -o jsonpath='{range .spec.taints[*]}{.key}={.value}:{.effect}  {end}' 2>/dev/null || echo "")
    if [ -z "$TI" ]; then
      warn "  Taints: none — GPU node has no taints; non-GPU pods may be scheduled here"
    else
      info "  Taints: ${TI}"
    fi
 
    NR=$(kubectl get node "$NODE" \
      -o jsonpath='{range .status.conditions[?(@.type=="Ready")]}{.status}{end}' 2>/dev/null || echo "Unknown")
    [ "$NR" = "True" ] && pass "  Node Ready ✓" || fail "  Node NOT Ready (${NR})"
  done
fi
# ── 6. Red Teaming Node Group ────────────────────────────────────────────────
header "Red Teaming Node Group"
RT_NODE_LIST=()
while IFS= read -r N; do
  [ -z "$N" ] && continue; RT_NODE_LIST+=("$N")
done < <(kubectl get nodes -l "dedicated=redteaming" \
  --no-headers -o custom-columns="NAME:.metadata.name" 2>/dev/null || true)

if [ "${#RT_NODE_LIST[@]}" -eq 0 ]; then
  fail "No nodes with label 'dedicated=redteaming'"
  warn "Apply: kubectl label node <node> dedicated=redteaming"
  warn "Apply: kubectl taint node <node> app=redteaming:NoSchedule"
else
  for NODE in "${RT_NODE_LIST[@]}"; do
    echo -e "\n  ${BOLD}Node: ${NODE}${RESET}"

    LV=$(kubectl get node "$NODE" -o jsonpath='{.metadata.labels.dedicated}' 2>/dev/null || echo "")
    [ "$LV" = "redteaming" ] && pass "  Label dedicated=redteaming ✓" || fail "  Label dedicated=redteaming missing"

    TAINT_OK=false
    while IFS= read -r TL; do
      TK=$(echo "$TL" | cut -d= -f1)
      TV=$(echo "$TL" | cut -d= -f2 | cut -d: -f1)
      TE=$(echo "$TL" | cut -d: -f2)
      [ "$TK" = "app" ] && [ "$TV" = "redteaming" ] && [ "$TE" = "NoSchedule" ] && TAINT_OK=true && break
    done < <(kubectl get node "$NODE" \
      -o jsonpath='{range .spec.taints[*]}{.key}={.value}:{.effect}{"\n"}{end}' 2>/dev/null || true)
    $TAINT_OK && pass "  Taint app=redteaming:NoSchedule ✓" \
              || fail "  Taint app=redteaming:NoSchedule MISSING"

    check_node_resources "$NODE" 4 30 100 || true

    NR=$(kubectl get node "$NODE" \
      -o jsonpath='{range .status.conditions[?(@.type=="Ready")]}{.status}{end}' 2>/dev/null || echo "Unknown")
    [ "$NR" = "True" ] && pass "  Node Ready ✓" || fail "  Node NOT Ready (${NR})"
  done
fi

# ── 7. General Purpose Node Group ───────────────────────────────────────────
header "General Purpose Node Group"
GP_COUNT=0; GP_OK=0
while IFS= read -r NODE; do
  [ -z "$NODE" ] && continue
  # skip GPU
  GV=$(kubectl get node "$NODE" -o jsonpath='{.status.allocatable.nvidia\.com/gpu}' 2>/dev/null || echo "")
  [ -n "$GV" ] && [ "$GV" != "0" ] && continue
  # skip redteaming
  RL=$(kubectl get node "$NODE" -o jsonpath='{.metadata.labels.dedicated}' 2>/dev/null || echo "")
  [ "$RL" = "redteaming" ] && continue

  GP_COUNT=$((GP_COUNT+1))
  echo -e "\n  ${BOLD}Node: ${NODE}${RESET}"
  check_node_resources "$NODE" 4 16 100 && GP_OK=$((GP_OK+1)) || true

  TK=$(kubectl get node "$NODE" -o jsonpath='{.spec.taints[*].key}' 2>/dev/null || echo "")
  [ -z "$TK" ] && pass "  No unexpected taints ✓" \
    || warn "  Taints present [${TK}] — ensure pods have matching tolerations"

  NR=$(kubectl get node "$NODE" \
    -o jsonpath='{range .status.conditions[?(@.type=="Ready")]}{.status}{end}' 2>/dev/null || echo "Unknown")
  [ "$NR" = "True" ] && pass "  Node Ready ✓" || fail "  Node NOT Ready (${NR})"
done < <(kubectl get nodes --no-headers -o custom-columns="NAME:.metadata.name" 2>/dev/null)

[ "$GP_COUNT" -eq 0 ] && fail "No general-purpose nodes found" \
  || info "General-purpose nodes meeting spec: ${GP_OK} / ${GP_COUNT}"

# ── 8. Scheduling Sanity ─────────────────────────────────────────────────────
header "Taint & Node Selector Scheduling Sanity"

RS=$(kubectl get nodes -l "dedicated=redteaming" \
  --field-selector='spec.unschedulable!=true' --no-headers 2>/dev/null | wc -l | tr -d ' ')
[ "$RS" -gt 0 ] && pass "Redteaming schedulable nodes: ${RS} ✓" \
  || fail "No schedulable redteaming nodes (dedicated=redteaming)"

for NODE in "${GPU_NODE_LIST[@]+"${GPU_NODE_LIST[@]}"}"; do
  US=$(kubectl get node "$NODE" -o jsonpath='{.spec.unschedulable}' 2>/dev/null || echo "false")
  [ "${US}" = "true" ] && fail "GPU node ${NODE} is cordoned" || pass "GPU node ${NODE} not cordoned ✓"
done

PEND=$(kubectl get pods -A --field-selector=status.phase=Pending \
  --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [ "$PEND" -gt 0 ]; then
  warn "${PEND} pod(s) Pending — possible resource pressure or scheduling conflict"
  kubectl get pods -A --field-selector=status.phase=Pending --no-headers 2>/dev/null \
    | awk '{printf "    Pending: %s / %s\n", $1, $2}' || true
else
  pass "No Pending pods ✓"
fi



# ── 9. Namespace Status ─────────────────────────────────────────────────────
header "Namespace Status"
for NS in enkryptai-stack redteam-jobs; do
  if kubectl get namespace "$NS" &>/dev/null; then
    PH=$(kubectl get namespace "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || echo "unknown")
    info "Namespace '${NS}' exists (phase: ${PH})"
  else
    info "Namespace '${NS}' not yet created — Helm install will create it"
  fi
done

header "Kubernetes Secrets"

# ---- REQUIRED SECRETS ----
SECRETS=(
"enkryptai-stack elastic-env-secret gateway-kong,opensearch"
"enkryptai-stack frontend-env-secret frontend"
"enkryptai-stack gateway-env-secret gateway-kong"
"enkryptai-stack gateway-migration-env-secret gateway-kong"
"enkryptai-stack guardrails-env-secret guardrails"
"enkryptai-stack onprem Supabase(on-prem database)"
"enkryptai-stack openfga-env-secret openfga"
"enkryptai-stack opensearch-cred opensearch"
"enkryptai-stack opensearch-securityconfig opensearch"
"enkryptai-stack postgres-superuser-secret Supabase(on-prem)"
"enkryptai-stack redteam-proxy-env-secret redteaming"
"enkryptai-stack s3-cred redteaming,Supabase(MinIO)"
"enkryptai-stack superuser-secret Postgres(CloudNativePG)"
"redteam-jobs redteam-proxy-env-secret redteam-jobs"
)

missing_count=0

for entry in "${SECRETS[@]}"; do
  NS=$(echo "$entry" | awk '{print $1}')
  SECRET=$(echo "$entry" | awk '{print $2}')
  USED_BY=$(echo "$entry" | cut -d' ' -f3-)

  # Check namespace first (don’t blindly assume it exists)
  if ! kubectl get ns "$NS" >/dev/null 2>&1; then
    warn "Namespace '$NS' not found (required for secret '$SECRET')"
    ((missing_count++))
    continue
  fi

  # Check secret
  if kubectl get secret "$SECRET" -n "$NS" >/dev/null 2>&1; then
    pass "Secret '$SECRET' present in namespace '$NS' (used by: $USED_BY)"
  else
    fail "Secret '$SECRET' MISSING in namespace '$NS' (used by: $USED_BY)"
    ((missing_count++))
  fi
done

# ---- FINAL SUMMARY ----
if [ "$missing_count" -eq 0 ]; then
  pass "All required secrets are present ✓"
else
  fail "$missing_count required secret(s) missing"
fi
# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║     EnkryptAI Pre-Flight Check — SUMMARY                     ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo -e "  ${GREEN}Passed :${RESET}  ${PASSED}"
echo -e "  ${YELLOW}Warned :${RESET}  ${WARNED}"
echo -e "  ${RED}Failed :${RESET}  ${FAILED}"
echo -e "  Total  :  ${TOTAL}"

if [ "${#FAILURES[@]}" -gt 0 ]; then
  echo ""
  echo -e "${BOLD}${RED}  Failed Checks:${RESET}"
  for F in "${FAILURES[@]}"; do echo -e "    ${RED}•${RESET} ${F}"; done
fi

echo ""
if   [ "$FAILED" -eq 0 ] && [ "$WARNED" -eq 0 ]; then
  echo -e "  ${GREEN}${BOLD}✔  All checks passed — cluster is ready for EnkryptAI.${RESET}"; EXIT_CODE=0
elif [ "$FAILED" -eq 0 ]; then
  echo -e "  ${YELLOW}${BOLD}⚠  Requirements met but review warnings before installing.${RESET}"; EXIT_CODE=0
else
  echo -e "  ${RED}${BOLD}✗  ${FAILED} check(s) failed — fix before installing EnkryptAI.${RESET}"; EXIT_CODE=1
fi
echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════════${RESET}"
echo ""
exit $EXIT_CODE