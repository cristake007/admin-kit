#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT_DIR/scripts/workflow_manifest.txt"

missing=0
while IFS= read -r rel; do
  [[ -z "$rel" || "$rel" =~ ^# ]] && continue
  file="$ROOT_DIR/$rel"
  if [[ ! -f "$file" ]]; then
    echo "MISSING: $rel"
    missing=1
    continue
  fi
  if ! rg -q 'run_install_workflow' "$file"; then
    echo "NON_COMPLIANT: $rel (missing run_install_workflow)"
    missing=1
  fi
  if ! rg -q 'check_installed\(\)' "$file"; then
    echo "NON_COMPLIANT: $rel (missing check_installed hook)"
    missing=1
  fi
  if ! rg -q 'check_conflicts\(\)' "$file"; then
    echo "NON_COMPLIANT: $rel (missing check_conflicts hook)"
    missing=1
  fi
  if ! rg -q 'install_step\(\)' "$file"; then
    echo "NON_COMPLIANT: $rel (missing install_step hook)"
    missing=1
  fi
  if ! rg -q 'summary_step\(\)|wf_default_summary' "$file"; then
    echo "NON_COMPLIANT: $rel (missing summary hook)"
    missing=1
  fi

done < "$MANIFEST"

if [[ "$missing" -eq 1 ]]; then
  exit 1
fi

echo "Workflow validation passed for all manifest scripts."
