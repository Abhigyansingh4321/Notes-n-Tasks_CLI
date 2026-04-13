#!/usr/bin/env bash

set -u

APP_TITLE="Notes-n-Tasks CLI"
VERSION="1.0"
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${XDG_STATE_HOME:-$APP_DIR/.state}"
TASK_FILE="$STATE_DIR/tasks.txt"
NOTE_FILE="$STATE_DIR/notes.txt"

mkdir -p "$(dirname "$TASK_FILE")"
touch "$TASK_FILE" "$NOTE_FILE"

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
MAGENTA="\033[35m"
BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"

term_width() {
  tput cols 2>/dev/null || echo 80
}

center_line() {
  local text="$1"
  local width
  width="$(term_width)"
  local len=${#text}
  if (( len >= width )); then
    printf '%s\n' "$text"
    return
  fi
  local pad=$(((width - len) / 2))
  printf '%*s%s\n' "$pad" "" "$text"
}

divider() {
  printf '%b%s%b\n' "$DIM" "$(printf '%*s' "$(term_width)" '' | tr ' ' '─')" "$RESET"
}

clear_screen() {
  printf '\033[2J\033[H'
}

count_tasks() {
  grep -cve '^[[:space:]]*$' "$TASK_FILE" 2>/dev/null || echo 0
}

latest_note() {
  tail -n 1 "$NOTE_FILE" 2>/dev/null || true
}

show_header() {
  clear_screen
  printf '%b' "$BOLD$CYAN"
  center_line "╭────────────────────────────────────────────────────────╮"
  center_line "│                    $APP_TITLE v$VERSION                │"
  center_line "╰────────────────────────────────────────────────────────╯"
  printf '%b' "$RESET"
  printf '\n'
}

show_dashboard() {
  show_header
  local task_count note
  task_count="$(count_tasks)"
  note="$(latest_note)"

  printf '%b' "$BOLD"
  printf '  %bStatus:%b %s\n' "$GREEN" "$RESET" "Ready"
  printf '  %bTasks:%b %s\n' "$YELLOW" "$RESET" "$task_count"
  printf '  %bLast Note:%b %s\n' "$MAGENTA" "$RESET" "${note:-No notes yet}"
  printf '  %bTip:%b Use the menu to add tasks or notes.\n' "$BLUE" "$RESET"
  printf '%b' "$RESET"

  divider
  printf '\n'
  printf '  %b1)%b Add task\n' "$CYAN" "$RESET"
  printf '  %b2)%b List tasks\n' "$CYAN" "$RESET"
  printf '  %b3)%b Add note\n' "$CYAN" "$RESET"
  printf '  %b4)%b Show notes\n' "$CYAN" "$RESET"
  printf '  %b5)%b Run command\n' "$CYAN" "$RESET"
  printf '  %b6)%b Clear data\n' "$CYAN" "$RESET"
  printf '  %b7)%b Exit\n' "$CYAN" "$RESET"
  printf '\n'
}

pause() {
  printf '\n%bPress Enter to continue...%b' "$DIM" "$RESET"
  read -r _
}

add_task() {
  printf 'Task title: '
  read -r task
  if [[ -n "${task// }" ]]; then
    printf '%s\n' "$task" >> "$TASK_FILE"
    printf '%bSaved task:%b %s\n' "$GREEN" "$RESET" "$task"
  else
    printf '%bEmpty task ignored.%b\n' "$RED" "$RESET"
  fi
  pause
}

list_tasks() {
  show_header
  printf '%bTasks%b\n' "$BOLD$YELLOW" "$RESET"
  divider
  if [[ ! -s "$TASK_FILE" ]]; then
    printf 'No tasks yet.\n'
  else
    nl -w2 -s'. ' "$TASK_FILE"
  fi
  pause
}

add_note() {
  printf 'Note: '
  read -r note
  if [[ -n "${note// }" ]]; then
    printf '%s\n' "$note" >> "$NOTE_FILE"
    printf '%bSaved note:%b %s\n' "$GREEN" "$RESET" "$note"
  else
    printf '%bEmpty note ignored.%b\n' "$RED" "$RESET"
  fi
  pause
}

show_notes() {
  show_header
  printf '%bNotes%b\n' "$BOLD$MAGENTA" "$RESET"
  divider
  if [[ ! -s "$NOTE_FILE" ]]; then
    printf 'No notes yet.\n'
  else
    nl -w2 -s'. ' "$NOTE_FILE"
  fi
  pause
}

run_command() {
  printf 'Command to run: '
  read -r cmd
  if [[ -z "${cmd// }" ]]; then
    printf '%bEmpty command ignored.%b\n' "$RED" "$RESET"
    pause
    return
  fi

  show_header
  printf '%bRunning:%b %s\n' "$BOLD$BLUE" "$RESET" "$cmd"
  divider
  bash -lc "$cmd"
  pause
}

clear_data() {
  : > "$TASK_FILE"
  : > "$NOTE_FILE"
  printf '%bAll data cleared.%b\n' "$GREEN" "$RESET"
  pause
}

trap 'printf "\033[0m"' EXIT

while true; do
  show_dashboard
  printf 'Choose an option [1-7]: '
  read -r choice
  case "$choice" in
    1) add_task ;;
    2) list_tasks ;;
    3) add_note ;;
    4) show_notes ;;
    5) run_command ;;
    6) clear_data ;;
    7) clear_screen; exit 0 ;;
    *) printf '%bInvalid choice.%b\n' "$RED" "$RESET"; pause ;;
  esac
done
