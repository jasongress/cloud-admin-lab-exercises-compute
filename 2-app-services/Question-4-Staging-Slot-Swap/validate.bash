#!/usr/bin/env bash
# ============================================================================
#  validate.bash — App Service Q4: Staging Slot + Swap. Read-only. Requires curl.
#  Exit = number of failed checks.
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

RG="$(lab_rg app04)"

PASS=0; FAIL=0; TOTAL=0
check() {
  local description="$1"; shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then echo "  PASS: $description"; PASS=$((PASS + 1))
  else echo "  FAIL: $description"; FAIL=$((FAIL + 1)); fi
}

app_name() { az webapp list -g "$RG" --query "[0].name" -o tsv 2>/dev/null; }

staging_slot_exists() {
  local a; a="$(app_name)"; [[ -z "$a" ]] && return 1
  [[ "$(az webapp deployment slot list -g "$RG" -n "$a" \
        --query "[?name=='staging'].name | [0]" -o tsv 2>/dev/null)" == "staging" ]]
}
prod_release_is_v2() {
  local a; a="$(app_name)"; [[ -z "$a" ]] && return 1
  [[ "$(az webapp config appsettings list -g "$RG" -n "$a" \
        --query "[?name=='RELEASE'].value | [0]" -o tsv 2>/dev/null)" == "v2" ]]
}
prod_http_200() {
  local a host; a="$(app_name)"; [[ -z "$a" ]] && return 1
  host="$(az webapp show -g "$RG" -n "$a" --query defaultHostName -o tsv 2>/dev/null)"
  [[ -z "$host" ]] && return 1
  [[ "$(curl -s -o /dev/null -w '%{http_code}' \
        --retry 3 --retry-delay 5 --retry-connrefused --max-time 30 \
        "https://$host" 2>/dev/null)" == "200" ]]
}

echo "======================================================"
echo " Validating App Service Q4: Staging Slot + Swap"
echo "   Resource group: $RG"
echo "======================================================"

check "A web app exists in '$RG'" \
  bash -c '[[ -n "$(az webapp list -g "'"$RG"'" --query "[0].name" -o tsv 2>/dev/null)" ]]'

check "A deployment slot named 'staging' exists" staging_slot_exists
check "Production carries the swapped release (RELEASE = v2)" prod_release_is_v2
check "Production is healthy (HTTP 200)" prod_http_200

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  echo "Tip: create the slot, set RELEASE=v2 ON THE STAGING SLOT, then swap it into"
  echo "     production. See solution.md."
fi
exit $FAIL
