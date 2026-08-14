#!/usr/bin/env bash
# ============================================================================
#  run-question.sh — start a Compute lab question
#
#  Usage:
#    scripts/run-question.sh 1
#    scripts/run-question.sh Question-1-Provision-Linux-VM
#
#  Runs the question's setup.bash (environment preflight), then prints its
#  problem.md so you can read the task.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Resolve a question directory from a number or a folder name, searching
# recursively so questions can live under resource subfolders (virtual-machines/, ...).
resolve_question_dir() {
  local input="$1"
  if [[ -d "$BASE_DIR/$input" ]]; then echo "$BASE_DIR/$input"; return 0; fi
  if [[ "$input" =~ ^[0-9]+$ ]]; then
    find "$BASE_DIR" -type d -name "Question-${input}-*" | sort -V | head -1
    return 0
  fi
  find "$BASE_DIR" -type d -name "$input" | head -1
}

list_questions() {
  echo "Available questions:"
  find "$BASE_DIR" -type d -name "Question-*" | sort -V | while read -r d; do
    echo "  $(basename "$d")"
  done
}

if [[ $# -lt 1 ]]; then
  echo "Usage: scripts/run-question.sh <question-number|question-dir>"
  list_questions
  exit 1
fi

QUESTION_DIR="$(resolve_question_dir "$*")"
if [[ -z "$QUESTION_DIR" || ! -d "$QUESTION_DIR" ]]; then
  echo -e "${RED}Error: could not find a question for '$*'${NC}" >&2
  list_questions
  exit 1
fi

DIR_NAME="$(basename "$QUESTION_DIR")"

if [[ -f "$QUESTION_DIR/setup.bash" ]]; then
  echo -e "${CYAN}Running setup for ${DIR_NAME}...${NC}"
  bash "$QUESTION_DIR/setup.bash"
else
  echo -e "${YELLOW}(no setup.bash for ${DIR_NAME} — nothing to preflight)${NC}"
fi

echo ""
echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN} Problem: ${DIR_NAME}${NC}"
echo -e "${CYAN}==========================================================${NC}"
if [[ -f "$QUESTION_DIR/problem.md" ]]; then
  cat "$QUESTION_DIR/problem.md"
else
  echo -e "${RED}(no problem.md found)${NC}"
fi

echo ""
echo -e "${YELLOW}Need a hint? Open ${DIR_NAME}/solution.md${NC}"
echo -e "${YELLOW}Done? Run: scripts/validate-question.sh $*${NC}"
