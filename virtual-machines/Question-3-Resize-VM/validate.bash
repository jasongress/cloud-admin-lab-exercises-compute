#!/usr/bin/env bash
# ============================================================================
#  validate.bash — Question 3: Resize a VM.  Read-only. Exit = # failed checks.
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

export RG="$(lab_rg vm03)"
export VM="dev-tool-vm"

PASS=0; FAIL=0; TOTAL=0
check() {
  local description="$1"; shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then echo "  PASS: $description"; PASS=$((PASS + 1))
  else echo "  FAIL: $description"; FAIL=$((FAIL + 1)); fi
}

vm_running() {
  [[ "$(az vm get-instance-view -g "$RG" -n "$VM" \
        --query "instanceView.statuses[?starts_with(code, 'PowerState/')].code | [0]" \
        -o tsv 2>/dev/null)" == "PowerState/running" ]]
}

echo "======================================================"
echo " Validating Question 3: Resize to Standard_D4s_v3"
echo "   Resource group: $RG   |   VM: $VM"
echo "======================================================"

check "VM '$VM' exists in '$RG'" \
  az vm show -g "$RG" -n "$VM"

check "VM size is Standard_D4s_v3" \
  bash -c '[[ "$(az vm show -g "$RG" -n "$VM" --query hardwareProfile.vmSize -o tsv 2>/dev/null)" == "Standard_D4s_v3" ]]'

check "VM power state is running" vm_running

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  echo "Some checks failed. See the FAIL lines above, or read solution.md."
fi
exit $FAIL
