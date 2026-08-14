#!/usr/bin/env bash
# ============================================================================
#  validate.bash — Question 1: Provision a Linux VM
# ============================================================================
#  Runs automated PASS/FAIL checks against your subscription. Exit code is the
#  number of failed checks (0 = everything passed).
#
#  This script only READS from Azure — it never creates or deletes anything.
#  Feel free to open it up: seeing how each requirement maps to an `az ... --query`
#  is itself good practice.
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

# Exported so the `bash -c '...'` predicates below can read them from the environment.
export RG="$(lab_rg vm01)"
export VM="dev-tool-vm"
export WANT_ADMIN="$LAB_ADMIN_USER"

PASS=0
FAIL=0
TOTAL=0

check() {
  local description="$1"
  shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then
    echo "  PASS: $description"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $description"
    FAIL=$((FAIL + 1))
  fi
}

echo "======================================================"
echo " Validating Question 1: Provision a Linux VM"
echo "   Resource group: $RG   |   VM: $VM"
echo "======================================================"

# 1. Resource group exists
check "Resource group '$RG' exists" \
  bash -c '[[ "$(az group exists --name "$RG")" == "true" ]]'

# 2. VM exists in the resource group
check "VM '$VM' exists in '$RG'" \
  az vm show -g "$RG" -n "$VM"

# 3. Size is Standard_D2s_v3
check "VM size is Standard_D2s_v3" \
  bash -c '[[ "$(az vm show -g "$RG" -n "$VM" --query hardwareProfile.vmSize -o tsv 2>/dev/null)" == "Standard_D2s_v3" ]]'

# 4. OS is Linux
check "VM operating system is Linux" \
  bash -c '[[ "$(az vm show -g "$RG" -n "$VM" --query storageProfile.osDisk.osType -o tsv 2>/dev/null)" == "Linux" ]]'

# 5. Image publisher is Canonical
check "VM image publisher is Canonical" \
  bash -c '[[ "$(az vm show -g "$RG" -n "$VM" --query storageProfile.imageReference.publisher -o tsv 2>/dev/null)" == "Canonical" ]]'

# 6. Image is Ubuntu 26.04 LTS (offer ubuntu-26_04-lts)
check "VM image is Ubuntu 26.04 LTS (offer 'ubuntu-26_04-lts')" \
  bash -c '[[ "$(az vm show -g "$RG" -n "$VM" --query storageProfile.imageReference.offer -o tsv 2>/dev/null)" == "ubuntu-26_04-lts" ]]'

# 7. Admin username matches the configured value
check "Admin username is '$WANT_ADMIN'" \
  bash -c '[[ "$(az vm show -g "$RG" -n "$VM" --query osProfile.adminUsername -o tsv 2>/dev/null)" == "$WANT_ADMIN" ]]'

# 8. Password authentication is disabled (SSH-key auth)
check "Password authentication is disabled (SSH key)" \
  bash -c '[[ "$(az vm show -g "$RG" -n "$VM" --query osProfile.linuxConfiguration.disablePasswordAuthentication -o tsv 2>/dev/null)" == "true" ]]'

# 9. VM power state is running
check "VM power state is running" \
  bash -c '[[ "$(az vm get-instance-view -g "$RG" -n "$VM" --query "instanceView.statuses[?starts_with(code, \`PowerState/\`)].code | [0]" -o tsv 2>/dev/null)" == "PowerState/running" ]]'

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Don't forget to clean up: scripts/cleanup-question.sh 1"
else
  echo "Some checks failed. Check the FAIL lines above, or read solution.md."
fi
exit $FAIL
