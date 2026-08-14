#!/usr/bin/env bash
# ============================================================================
#  validate-question.sh — run a question's automated checks
#
#  Usage:
#    scripts/validate-question.sh 1
#    scripts/validate-question.sh Question-1-Provision-Linux-VM
#    scripts/validate-question.sh all
#
#  Prints PASS/FAIL per check. Exit code 0 = all checks passed, non-zero = some
#  failed.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

resolve_question_dir() {
  local input="$1"
  if [[ -d "$BASE_DIR/$input" ]]; then echo "$BASE_DIR/$input"; return 0; fi
  if [[ "$input" =~ ^[0-9]+$ ]]; then
    find "$BASE_DIR" -type d -name "Question-${input}-*" | sort -V | head -1
    return 0
  fi
  find "$BASE_DIR" -type d -name "$input" | head -1
}

run_validation() {
  local question_dir="$1"
  local dir_name; dir_name="$(basename "$question_dir")"
  local validate_script="$question_dir/validate.bash"

  if [[ ! -f "$validate_script" ]]; then
    echo -e "${YELLOW}SKIP: ${dir_name} — no validate.bash found${NC}"
    return 2
  fi

  echo ""
  echo -e "${CYAN}==========================================================${NC}"
  echo -e "${CYAN} Validating: ${dir_name}${NC}"
  echo -e "${CYAN}==========================================================${NC}"
  bash "$validate_script"
  return $?
}

if [[ $# -lt 1 ]]; then
  echo "Usage: scripts/validate-question.sh <question-number|question-dir|all>"
  exit 1
fi

INPUT="$*"

if [[ "$INPUT" == "all" ]]; then
  TOTAL=0; PASSED=0; FAILED=0; SKIPPED=0
  echo -e "${CYAN}+========================================================+${NC}"
  echo -e "${CYAN}|        Compute Lab — Full Validation                   |${NC}"
  echo -e "${CYAN}+========================================================+${NC}"

  # Discover questions dynamically so this can never go stale as questions are added.
  while read -r QUESTION_DIR; do
    [[ -z "$QUESTION_DIR" ]] && continue
    TOTAL=$((TOTAL + 1))
    run_validation "$QUESTION_DIR"
    rc=$?
    if [[ $rc -eq 0 ]]; then PASSED=$((PASSED + 1))
    elif [[ $rc -eq 2 ]]; then SKIPPED=$((SKIPPED + 1))
    else FAILED=$((FAILED + 1)); fi
  done < <(find "$BASE_DIR" -type d -name "Question-*" | sort -V)

  echo ""
  echo -e "${CYAN}==========================================================${NC}"
  echo -e "${CYAN} Summary${NC}"
  echo -e "${CYAN}==========================================================${NC}"
  echo -e "  ${GREEN}Passed:  $PASSED${NC}"
  echo -e "  ${RED}Failed:  $FAILED${NC}"
  echo -e "  ${YELLOW}Skipped: $SKIPPED${NC}"
  echo -e "  Total:   $TOTAL"
  [[ $FAILED -gt 0 ]] && exit 1 || exit 0
else
  QUESTION_DIR="$(resolve_question_dir "$INPUT")"
  if [[ -z "$QUESTION_DIR" || ! -d "$QUESTION_DIR" ]]; then
    echo -e "${RED}Error: could not find a question for '$INPUT'${NC}" >&2
    find "$BASE_DIR" -type d -name "Question-*" | sort -V | while read -r d; do
      echo "  $(basename "$d")"
    done
    exit 1
  fi
  run_validation "$QUESTION_DIR"
  exit $?
fi
