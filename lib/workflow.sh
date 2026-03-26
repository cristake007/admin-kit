#!/usr/bin/env bash

[[ -n "${__LIB_WORKFLOW_SH:-}" ]] && return 0
__LIB_WORKFLOW_SH=1

: "${WORKFLOW_CHANGED:=0}"
: "${WORKFLOW_ACTIONS:=}"

wf_reset() {
  WORKFLOW_CHANGED=0
  WORKFLOW_ACTIONS=""
}

wf_add_action() {
  local message="$1"
  if [[ -z "${WORKFLOW_ACTIONS}" ]]; then
    WORKFLOW_ACTIONS="$message"
  else
    WORKFLOW_ACTIONS+=$'\n'"$message"
  fi
}

wf_mark_changed() {
  WORKFLOW_CHANGED=1
  [[ -n "${1:-}" ]] && wf_add_action "$1"
}

wf_default_summary() {
  local name="$1"
  local state="$2"
  echo
  echo_note "Post-install summary (${name})"
  echo_note "State: ${state}"
  if [[ -n "${WORKFLOW_ACTIONS}" ]]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && echo_note "- $line"
    done <<< "$WORKFLOW_ACTIONS"
  else
    echo_note "- No actions recorded"
  fi
}

run_install_workflow() {
  local name="$1"
  local check_installed_fn="$2"
  local check_conflicts_fn="$3"
  local install_fn="$4"
  local summary_fn="${5:-wf_default_summary}"
  local state="no-op"

  wf_reset

  if "$check_installed_fn"; then
    wf_add_action "Already installed/configured"
    "$summary_fn" "$name" "$state"
    return 0
  fi

  if ! "$check_conflicts_fn"; then
    wf_add_action "Conflict detected"
    "$summary_fn" "$name" "blocked"
    return 1
  fi

  if ! "$install_fn"; then
    wf_add_action "Installation/configuration failed"
    "$summary_fn" "$name" "failed"
    return 1
  fi

  if [[ "${WORKFLOW_CHANGED}" -eq 1 ]]; then
    state="changed"
  fi
  "$summary_fn" "$name" "$state"
  return 0
}
