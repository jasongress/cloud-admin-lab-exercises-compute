#!/usr/bin/env bash
# ============================================================================
#  cleanup-question.sh — tear down the resources a question created
#
#  Usage:
#    scripts/cleanup-question.sh 1
#    scripts/cleanup-question.sh Question-1-Provision-Linux-VM
#    scripts/cleanup-question.sh all
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
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

run_cleanup() {
  local question_dir="$1"
  local dir_name; dir_name="$(basename "$question_dir")"
  local cleanup_script="$question_dir/cleanup.bash"

  if [[ ! -f "$cleanup_script" ]]; then
    echo -e "${YELLOW}SKIP: ${dir_name} — no cleanup.bash found${NC}"
    return 0
  fi
  echo -e "${CYAN}Cleaning up ${dir_name}...${NC}"
  bash "$cleanup_script"
}

if [[ $# -lt 1 ]]; then
  echo "Usage: scripts/cleanup-question.sh <question-number|question-dir|all>"
  exit 1
fi

INPUT="$*"

if [[ "$INPUT" == "all" ]]; then
  while read -r QUESTION_DIR; do
    [[ -z "$QUESTION_DIR" ]] && continue
    run_cleanup "$QUESTION_DIR"
  done < <(find "$BASE_DIR" -type d -name "Question-*" | sort -V)
else
  QUESTION_DIR="$(resolve_question_dir "$INPUT")"
  if [[ -z "$QUESTION_DIR" || ! -d "$QUESTION_DIR" ]]; then
    echo -e "${RED}Error: could not find a question for '$INPUT'${NC}" >&2
    exit 1
  fi
  run_cleanup "$QUESTION_DIR"
fi
