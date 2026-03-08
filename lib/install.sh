#!/usr/bin/env bash
set -Eeuo pipefail

[[ -n "${__LIB_INSTALL_SH:-}" ]] && return 0
__LIB_INSTALL_SH=1

install_stage() {
  local name="${1:?stage name required}"
  info ""
  info "[Install Stage] ${name}"
}

run_install_workflow() {
  local workflow_name="${1:?workflow name required}"
  local confirm_prompt="${2:?confirm prompt required}"
  local message_fn="${3:?message function required}"
  local checks_fn="${4:?checks function required}"
  local install_fn="${5:?install function required}"
  local post_install_fn="${6:-}"

  install_stage "Install message"
  "$message_fn"

  install_stage "Checks"
  "$checks_fn"

  install_stage "Install"
  if ! confirm_proceed "$confirm_prompt"; then
    operator_aborted
    return 0
  fi
  "$install_fn"

  install_stage "Post-install"
  if [[ -n "$post_install_fn" ]]; then
    "$post_install_fn"
  fi

  success "${workflow_name} workflow completed."
}
