#!/usr/bin/env bash
# ============================================================================
#  validate.bash — App Service Q1: Deploy a Web App
# ============================================================================
#  Read-only. Finds THE plan and web app in this question's resource group
#  (so your chosen names don't matter), then curls the app to prove it's live.
#  Exit = number of failed checks. Requires: curl.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
find_config() {
  local dir="$SCRIPT_DIR"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/lab-config.sh" ]]; then echo "$dir/lab-config.sh"; return 0; fi
    dir="$(dirname "$dir")"
  done
  return 1
}
CONFIG="$(find_config)" || { echo "ERROR: could not find lab-config.sh" >&2; exit 1; }
# shellcheck source=/dev/null
source "$CONFIG"

RG="$(lab_rg app01)"

PASS=0; FAIL=0; TOTAL=0
check() {
  local description="$1"; shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then echo "  PASS: $description"; PASS=$((PASS + 1))
  else echo "  FAIL: $description"; FAIL=$((FAIL + 1)); fi
}

# --- discovery helpers (find the single plan/app in the RG) -----------------
plan_name() { az appservice plan list -g "$RG" --query "[0].name" -o tsv 2>/dev/null; }
app_name()  { az webapp list        -g "$RG" --query "[0].name" -o tsv 2>/dev/null; }

plan_exists() { [[ -n "$(plan_name)" ]]; }
plan_is_linux_paid() {
  local p; p="$(plan_name)"; [[ -z "$p" ]] && return 1
  local reserved tier
  reserved="$(az appservice plan show -g "$RG" -n "$p" --query reserved  -o tsv 2>/dev/null)"
  tier="$(az appservice plan show    -g "$RG" -n "$p" --query sku.tier -o tsv 2>/dev/null)"
  [[ "$reserved" == "true" && -n "$tier" && "$tier" != "Free" && "$tier" != "Shared" ]]
}
app_exists() { [[ -n "$(app_name)" ]]; }
app_runtime_node() {
  local a fx; a="$(app_name)"; [[ -z "$a" ]] && return 1
  fx="$(az webapp config show -g "$RG" -n "$a" --query linuxFxVersion -o tsv 2>/dev/null)"
  grep -qi '^NODE' <<<"$fx"
}
app_http_200() {
  local a host; a="$(app_name)"; [[ -z "$a" ]] && return 1
  host="$(az webapp show -g "$RG" -n "$a" --query defaultHostName -o tsv 2>/dev/null)"
  [[ -z "$host" ]] && return 1
  [[ "$(curl -s -o /dev/null -w '%{http_code}' \
        --retry 3 --retry-delay 5 --retry-connrefused --max-time 30 \
        "https://$host" 2>/dev/null)" == "200" ]]
}

echo "======================================================"
echo " Validating App Service Q1: Deploy a Web App"
echo "   Resource group: $RG"
echo "======================================================"

check "Resource group '$RG' exists" \
  bash -c '[[ "$(az group exists --name "'"$RG"'")" == "true" ]]'

check "An App Service plan exists in the resource group" plan_exists
check "The plan is Linux and a paid tier (not Free/Shared)" plan_is_linux_paid
check "A web app exists in the resource group" app_exists
check "The web app uses a Node runtime" app_runtime_node
check "The web app answers HTTP 200 on its default hostname" app_http_200

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  a="$(app_name)"
  [[ -n "$a" ]] && echo "Hint: found web app '$a'. Its URL: https://$(az webapp show -g "$RG" -n "$a" --query defaultHostName -o tsv 2>/dev/null)"
  echo "A brand-new app can be slow on first hit (cold start) — wait and re-run. Or read solution.md."
fi
exit $FAIL
