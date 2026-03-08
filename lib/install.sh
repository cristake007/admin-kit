#!/usr/bin/env bash
set -Eeuo pipefail

[[ -n "${__LIB_INSTALL_SH:-}" ]] && return 0
__LIB_INSTALL_SH=1

workflow_stage() {
  local name="${1:?stage name required}"
  info ""
  info "[Stage] ${name}"
}

_run_optional_stage() {
  local stage_name="${1:?stage name required}"
  local fn_name="${2:-}"

  workflow_stage "$stage_name"
  if [[ -z "$fn_name" ]]; then
    info "No actions required for this stage."
    return 0
  fi

  "$fn_name"
}

run_install_workflow() {
  local workflow_name="${1:?workflow name required}"
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

  workflow_stage "Confirmation"
  if ! confirm_proceed "$confirm_prompt"; then
    operator_aborted
    return 0
  fi

  _run_optional_stage "Installation" "$install_fn"
  _run_optional_stage "Optional service/config steps" "$service_config_fn"
  _run_optional_stage "Post-install verification" "$verify_fn"
  _run_optional_stage "Final summary" "$summary_fn"

  success "${workflow_name} workflow completed."
}

run_action_workflow() {
  local workflow_name="${1:?workflow name required}"
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

  workflow_stage "Check whether change is needed"
  if [[ -n "$needed_check_fn" ]]; then
    if ! "$needed_check_fn"; then
      success "Requested state is already satisfied; no change required."
      _run_optional_stage "Verify resulting state" "$verify_fn"
      _run_optional_stage "Final summary" "$summary_fn"
      success "${workflow_name} workflow completed."
      return 0
    fi
  else
    info "No change-needed check provided; continuing."
  fi

  _run_optional_stage "Conflict and safety checks" "$safety_checks_fn"

  workflow_stage "Confirmation"
  if ! confirm_proceed "$confirm_prompt"; then
    operator_aborted
    return 0
  fi

  _run_optional_stage "Apply change" "$apply_fn"
  _run_optional_stage "Verify resulting state" "$verify_fn"
  _run_optional_stage "Final summary" "$summary_fn"

  success "${workflow_name} workflow completed."
}
