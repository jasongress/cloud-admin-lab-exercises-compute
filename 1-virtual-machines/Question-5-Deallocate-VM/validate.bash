#!/usr/bin/env bash
# ============================================================================
#  validate.bash — Question 5: Deallocate a VM. Read-only. Exit = # failed.
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

RG="$(lab_rg vm05)"
VM="dev-tool-vm"

PASS=0; FAIL=0; TOTAL=0
check() {
  local description="$1"; shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then echo "  PASS: $description"; PASS=$((PASS + 1))
  else echo "  FAIL: $description"; FAIL=$((FAIL + 1)); fi
}

# Power-state helper (clean single-quoted JMESPath). Returns the PowerState code.
power_state() {
  az vm get-instance-view -g "$RG" -n "$VM" \
    --query "instanceView.statuses[?starts_with(code, 'PowerState/')].code | [0]" \
    -o tsv 2>/dev/null
}
vm_deallocated() { [[ "$(power_state)" == "PowerState/deallocated" ]]; }

echo "======================================================"
echo " Validating Question 5: Deallocate '$VM'"
echo "   Resource group: $RG   |   VM: $VM"
echo "======================================================"

check "VM '$VM' still exists (was not deleted)" \
  az vm show -g "$RG" -n "$VM"

check "VM power state is 'deallocated' (compute billing stopped)" \
  vm_deallocated

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  cur="$(power_state)"
  [[ -n "$cur" ]] && echo "Hint: current power state is '${cur}'. The money-saving state is 'PowerState/deallocated'."
  echo "See the FAIL lines above, or read solution.md."
fi
exit $FAIL
