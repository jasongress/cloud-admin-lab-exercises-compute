#!/usr/bin/env bash
# ============================================================================
#  validate.bash — App Service Q2: Configure App Settings. Read-only.
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

RG="$(lab_rg app02)"

PASS=0; FAIL=0; TOTAL=0
check() {
  local description="$1"; shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then echo "  PASS: $description"; PASS=$((PASS + 1))
  else echo "  FAIL: $description"; FAIL=$((FAIL + 1)); fi
}

app_name() { az webapp list -g "$RG" --query "[0].name" -o tsv 2>/dev/null; }

# Read one app setting's value by name.
setting_value() {  # $1 = setting name
  local a; a="$(app_name)"; [[ -z "$a" ]] && return 1
  az webapp config appsettings list -g "$RG" -n "$a" \
    --query "[?name=='$1'].value | [0]" -o tsv 2>/dev/null
}
setting_is() { [[ "$(setting_value "$1")" == "$2" ]]; }

echo "======================================================"
echo " Validating App Service Q2: Configure App Settings"
echo "   Resource group: $RG"
echo "======================================================"

check "A web app exists in '$RG'" \
  bash -c '[[ -n "$(az webapp list -g "'"$RG"'" --query "[0].name" -o tsv 2>/dev/null)" ]]'

check "App setting ENVIRONMENT = production" \
  setting_is ENVIRONMENT production

check "App setting FEATURE_FLAG = beta" \
  setting_is FEATURE_FLAG beta

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  echo "See the FAIL lines above, or read solution.md."
fi
exit $FAIL
