#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/bootstrap.sh"
require "lib/log.sh"
require "lib/core.sh"

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
    printf '  got: %s\n' "$haystack"
  fi
}

assert_eq() {
  local got="$1"
  local expected="$2"
  local msg="$3"

  if [[ "$got" == "$expected" ]]; then
    record_pass "$msg"
  else
    record_fail "$msg"
    printf '  expected: %s\n' "$expected"
    printf '  got: %s\n' "$got"
  fi
}

# 1) run should fail with 127 when target is missing
set +e
missing_output="$(run "$ROOT_DIR/scripts/does_not_exist.sh" 2>&1)"
missing_rc=$?
set -e
assert_eq "$missing_rc" "127" "run returns 127 when script target does not exist"
assert_contains "$missing_output" "Script not found" "run prints missing script message"

# 2) run should execute script and return 0 on success
ok_script="$(mktemp)"
cat > "$ok_script" <<'SCRIPT'
#!/usr/bin/env bash
echo "ok-script-ran"
SCRIPT
chmod +x "$ok_script"

set +e
ok_output="$(run "$ok_script" 2>&1)"
ok_rc=$?
set -e
assert_eq "$ok_rc" "0" "run returns 0 when child script succeeds"
assert_contains "$ok_output" "ok-script-ran" "run forwards stdout from child script"

# 3) run should return child exit code and include debug details on failure
fail_script="$(mktemp)"
cat > "$fail_script" <<'SCRIPT'
#!/usr/bin/env bash
echo "about-to-fail"
exit 42
SCRIPT
chmod +x "$fail_script"

set +e
fail_output="$(run "$fail_script" 2>&1)"
fail_rc=$?
set -e
assert_eq "$fail_rc" "42" "run returns child script exit code"
assert_contains "$fail_output" "failed (exit 42)" "run prints child failure message"
assert_contains "$fail_output" "Log:" "run prints log file location"

rm -f "$ok_script" "$fail_script"

printf '\nSummary: %d passed, %d failed\n' "$pass_count" "$fail_count"

if [[ "$fail_count" -gt 0 ]]; then
  exit 1
fi
