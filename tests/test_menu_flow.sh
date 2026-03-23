#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

pass_count=0
fail_count=0

record_pass() {
  pass_count=$((pass_count + 1))
  printf 'PASS: %s\n' "$1"
}

record_fail() {
  fail_count=$((fail_count + 1))
  printf 'FAIL: %s\n' "$1"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="$3"

  if [[ "$haystack" == *"$needle"* ]]; then
    record_pass "$msg"
  else
    record_fail "$msg"
    printf '  expected to contain: %s\n' "$needle"
  fi
}

run_menu_case() {
  local input="$1"
  TERM=xterm timeout 8s bash "$ROOT_DIR/admin_menu.sh" <<< "$input" 2>&1
}

# Case 1: invalid main menu input should show validation error, then exit cleanly.
set +e
case1_output="$(run_menu_case $'9\n0\n')"
case1_rc=$?
set -e
if [[ "$case1_rc" -eq 0 ]]; then
  record_pass "menu exits with code 0 after invalid option then exit"
else
  record_fail "menu exits with code 0 after invalid option then exit"
  printf '  got rc=%s\n' "$case1_rc"
fi
assert_contains "$case1_output" "Invalid option. Please try again." "main menu invalid option is handled"
assert_contains "$case1_output" "Thank you for using the System Administration Menu." "exit message is shown"

# Case 2: enter SYSTEM menu, choose invalid option, continue, return to main, then exit.
set +e
case2_output="$(run_menu_case $'1\nabc\n\n0\n0\n')"
case2_rc=$?
set -e
if [[ "$case2_rc" -eq 0 ]]; then
  record_pass "system submenu invalid option path returns to main and exits"
else
  record_fail "system submenu invalid option path returns to main and exits"
  printf '  got rc=%s\n' "$case2_rc"
fi
assert_contains "$case2_output" "SYSTEM" "system screen is displayed"
assert_contains "$case2_output" "Invalid option. Please try again." "system submenu invalid option is handled"
assert_contains "$case2_output" "Press Enter to continue..." "pause is shown after submenu invalid option"

printf '\nSummary: %d passed, %d failed\n' "$pass_count" "$fail_count"

if [[ "$fail_count" -gt 0 ]]; then
  exit 1
fi
