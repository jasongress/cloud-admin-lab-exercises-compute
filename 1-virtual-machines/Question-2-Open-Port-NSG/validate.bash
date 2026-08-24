#!/usr/bin/env bash
# ============================================================================
#  validate.bash — Question 2: Open a Port with a Network Security Group
# ============================================================================
#  Read-only checks. Exit code = number of failed checks (0 = all passed).
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

RG="$(lab_rg vm02)"
VM="dev-tool-vm"

PASS=0; FAIL=0; TOTAL=0
check() {
  local description="$1"; shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then echo "  PASS: $description"; PASS=$((PASS + 1))
  else echo "  FAIL: $description"; FAIL=$((FAIL + 1)); fi
}

# Robust across both ways of opening the port:
#   - `az vm open-port`            -> sets destinationPortRange = "8080"
#   - `az network nsg rule create` -> may set destinationPortRanges = ["8080"]
# We list every inbound Allow rule in the RG's NSGs and look for 8080 in either field.
port_8080_open() {
  az network nsg list -g "$RG" \
    --query "[].securityRules[?access=='Allow' && direction=='Inbound'].[destinationPortRange, destinationPortRanges]" \
    -o tsv 2>/dev/null | grep -qw 8080
}

echo "======================================================"
echo " Validating Question 2: Open TCP 8080"
echo "   Resource group: $RG   |   VM: $VM"
echo "======================================================"

check "Resource group '$RG' exists" \
  bash -c '[[ "$(az group exists --name "'"$RG"'")" == "true" ]]'

check "VM '$VM' exists in '$RG'" \
  az vm show -g "$RG" -n "$VM"

check "An inbound Allow rule opens TCP port 8080" \
  port_8080_open

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  echo "Some checks failed. See the FAIL lines above, or read solution.md."
fi
exit $FAIL
