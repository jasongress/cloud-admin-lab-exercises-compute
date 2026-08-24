#!/usr/bin/env bash
# ============================================================================
#  validate.bash — Question 4: Attach a Data Disk. Read-only. Exit = # failed.
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

export RG="$(lab_rg vm04)"
export VM="dev-tool-vm"
export DISK="dev-tool-data"

PASS=0; FAIL=0; TOTAL=0
check() {
  local description="$1"; shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then echo "  PASS: $description"; PASS=$((PASS + 1))
  else echo "  FAIL: $description"; FAIL=$((FAIL + 1)); fi
}

# Helpers — clean single-quoted JMESPath filters on the VM's dataDisks list.
disk_field() {  # $1 = jmespath field to read for the disk named $DISK
  az vm show -g "$RG" -n "$VM" \
    --query "storageProfile.dataDisks[?name=='$DISK'].$1 | [0]" -o tsv 2>/dev/null
}
disk_attached() { [[ -n "$(disk_field name)" ]]; }
disk_is_32gib() { [[ "$(disk_field diskSizeGb)" == "32" ]]; }
disk_is_managed() { [[ -n "$(disk_field managedDisk.id)" ]]; }

echo "======================================================"
echo " Validating Question 4: Attach 32 GiB data disk '$DISK'"
echo "   Resource group: $RG   |   VM: $VM"
echo "======================================================"

check "VM '$VM' exists in '$RG'" \
  az vm show -g "$RG" -n "$VM"

# Disk '$DISK' is listed among the VM's attached data disks
check "Data disk '$DISK' is attached to the VM" disk_attached

# That attached disk is 32 GiB
check "Attached disk '$DISK' is 32 GiB" disk_is_32gib

# It is a managed disk (managedDisk.id is populated)
check "Disk '$DISK' is a managed disk" disk_is_managed

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  echo "Some checks failed. See the FAIL lines above, or read solution.md."
fi
exit $FAIL
