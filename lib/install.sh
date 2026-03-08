#!/usr/bin/env bash
set -Eeuo pipefail

[[ -n "${__LIB_INSTALL_SH:-}" ]] && return 0
__LIB_INSTALL_SH=1

_run_optional_stage() {
  local _stage_name="${1:?stage name required}"
  local fn_name="${2:-}"

  [[ -n "$fn_name" ]] || return 0
  "$fn_name"
}

run_install_workflow() {
  local _workflow_name="${1:?workflow name required}"
  local confirm_prompt="${2:-Proceed with installation?}"
  local explain_fn="${3:-}"
  local prereq_fn="${4:-}"
  local installed_check_fn="${5:-}"
  local conflict_check_fn="${6:-}"
  local plan_fn="${7:-}"
  local install_fn="${8:-}"
  local service_config_fn="${9:-}"
  local verify_fn="${10:-}"
  local summary_fn="${11:-}"

  _run_optional_stage "Explain what will happen" "$explain_fn"
  _run_optional_stage "Prerequisite and OS checks" "$prereq_fn"
  _run_optional_stage "Already-installed check" "$installed_check_fn"
  _run_optional_stage "Conflict check" "$conflict_check_fn"
  _run_optional_stage "What will be installed" "$plan_fn"

  if ! confirm_proceed "$confirm_prompt"; then
    operator_aborted
    return 0
  fi

  _run_optional_stage "Installation" "$install_fn"
  _run_optional_stage "Optional service/config steps" "$service_config_fn"
  _run_optional_stage "Post-install verification" "$verify_fn"
  _run_optional_stage "Final summary" "$summary_fn"
}

run_action_workflow() {
  local _workflow_name="${1:?workflow name required}"
  local confirm_prompt="${2:-Proceed with change?}"
  local explain_fn="${3:-}"
  local gather_validate_fn="${4:-}"
  local current_state_fn="${5:-}"
  local needed_check_fn="${6:-}"
  local safety_checks_fn="${7:-}"
  local apply_fn="${8:-}"
  local verify_fn="${9:-}"
  local summary_fn="${10:-}"

  _run_optional_stage "Explain what will happen" "$explain_fn"
  _run_optional_stage "Gather and validate input" "$gather_validate_fn"
  _run_optional_stage "Show current state" "$current_state_fn"

  if [[ -n "$needed_check_fn" ]]; then
    if ! "$needed_check_fn"; then
      info "No change needed."
      _run_optional_stage "Verify resulting state" "$verify_fn"
      _run_optional_stage "Final summary" "$summary_fn"
      return 0
    fi
  fi

  _run_optional_stage "Conflict and safety checks" "$safety_checks_fn"

  if ! confirm_proceed "$confirm_prompt"; then
    operator_aborted
    return 0
  fi

  _run_optional_stage "Apply change" "$apply_fn"
  _run_optional_stage "Verify resulting state" "$verify_fn"
  _run_optional_stage "Final summary" "$summary_fn"
}
