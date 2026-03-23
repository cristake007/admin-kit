# Failure-point check for the Bash TUI menu

This document lists high-risk paths discovered in `admin_menu.sh` and the supporting libs, plus whether a test now covers them.

## Covered by tests

1. **Missing target script when dispatching a menu action**
   - Risk: `run` is called with a path that does not exist.
   - Expected behavior: return `127` with a readable error message and caller context.
   - Coverage: `tests/test_core.sh`.

2. **Child script failure propagation**
   - Risk: menu-triggered script fails but failure code is swallowed.
   - Expected behavior: preserve child exit code, print failure and log path.
   - Coverage: `tests/test_core.sh`.

3. **Main menu invalid input loop**
   - Risk: user enters unsupported option and app crashes or exits unexpectedly.
   - Expected behavior: show validation message and keep running.
   - Coverage: `tests/test_menu_flow.sh` (invalid option then clean exit).

4. **Submenu invalid input + pause interaction**
   - Risk: submenu input validation path fails to recover.
   - Expected behavior: display error, pause, then continue loop.
   - Coverage: `tests/test_menu_flow.sh` (SYSTEM screen invalid option path).

## Not yet fully automated (recommended next)

1. **Environment command dependency failures**
   - `display_header` relies on `tput`, `lscpu`, `who`, `uptime`, `hostname`, `/proc/cpuinfo`.
   - Some minimal/containerized systems can miss one or more commands or have non-TTY `TERM` issues.
   - Recommendation: add fallback behavior tests for missing commands and non-interactive terminals.

2. **Privileged script execution from menu options**
   - Many actions require root/sudo and mutate system state.
   - Recommendation: add injectable command wrappers/mocks so option-to-script wiring can be tested without performing privileged operations.

3. **EOF / empty-input handling on `read` loops**
   - If stdin closes unexpectedly, loop behavior can vary by shell context.
   - Recommendation: explicitly test EOF handling and decide whether to auto-exit with message.
