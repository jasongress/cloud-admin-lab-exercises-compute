#!/usr/bin/env bash
# ============================================================================
#  validate.bash — App Service Q3: Scale Out. Read-only. Exit = # failed checks.
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

RG="$(lab_rg app03)"

PASS=0; FAIL=0; TOTAL=0
check() {
  local description="$1"; shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then echo "  PASS: $description"; PASS=$((PASS + 1))
  else echo "  FAIL: $description"; FAIL=$((FAIL + 1)); fi
}

plan_name()      { az appservice plan list -g "$RG" --query "[0].name" -o tsv 2>/dev/null; }
plan_capacity()  {
  local p; p="$(plan_name)"; [[ -z "$p" ]] && return 1
  az appservice plan show -g "$RG" -n "$p" --query sku.capacity -o tsv 2>/dev/null
}
capacity_is_3()  { [[ "$(plan_capacity)" == "3" ]]; }

echo "======================================================"
echo " Validating App Service Q3: Scale Out to 3 instances"
echo "   Resource group: $RG"
echo "======================================================"

check "A web app exists in '$RG'" \
  bash -c '[[ -n "$(az webapp list -g "'"$RG"'" --query "[0].name" -o tsv 2>/dev/null)" ]]'

check "The App Service plan runs 3 instances" capacity_is_3

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  cur="$(plan_capacity)"
  [[ -n "$cur" ]] && echo "Hint: the plan currently runs ${cur} instance(s); the target is 3."
  echo "See the FAIL lines above, or read solution.md."
fi
exit $FAIL
