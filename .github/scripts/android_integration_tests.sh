#!/usr/bin/env bash
# Runs one half of the example app's integration tests on emulator-5554.
#
# On CI the run sometimes never reaches a test, although the other half, with
# the same app on the same kind of runner, does. It fails one of two ways:
# - Once the app has started, flutter test gives itself a fixed 5 s to connect
#   to the app's VM Service, through adb's port forward, and that runs out.
# - Nothing more is printed after the install: flutter test waits, with no
#   limit of its own, for the app to report its VM Service. A healthy run
#   finishes its first test 5 to 7 s after the install, so a run that has
#   finished none STALL_SECONDS after it is stopped, after printing whether
#   the app is running and the app's last log lines.
# Either way the run starts once more; the app is already built, so the retry
# costs little.
#
# Usage, from auto_route/example: android_integration_tests.sh <shard index>
# The results and the output go to $RUNNER_TEMP, as the report step expects.

set -o pipefail

STALL_SECONDS=${STALL_SECONDS:-90}
results="$RUNNER_TEMP/test-results.json"
output="$RUNNER_TEMP/test-output.txt"

# Prints what the emulator shows of the app, for a run that stalled.
describe_app() {
  echo "::group::The app on the emulator"
  echo "App process: $(adb -s emulator-5554 shell pidof com.ma.example || echo 'not running')"
  adb -s emulator-5554 logcat -d -t 300 | grep -iE "flutter|com\.ma\.example|AndroidRuntime|VM Service" | tail -40
  echo "::endgroup::"
}

# Runs the tests; returns 124 when it stopped a run that stalled after the install.
run_tests() {
  rm -f "$results"
  flutter test --reporter github --file-reporter "json:$results" \
    integration_test/all_tests.dart --total-shards 2 --shard-index "$1" -d emulator-5554 \
    > >(tee "$output") 2>&1 &
  local pid=$! installed_at=""
  while kill -0 "$pid" 2> /dev/null; do
    sleep 5
    if [ -z "$installed_at" ] && grep -q "^Installing build/" "$output" 2> /dev/null; then
      installed_at=$(date +%s)
    fi
    if [ -n "$installed_at" ] && ! grep -q '"type":"testDone"' "$results" 2> /dev/null &&
      [ $(($(date +%s) - installed_at)) -ge "$STALL_SECONDS" ]; then
      echo "::warning title=The Android tests stalled::No test finished within $STALL_SECONDS s of the install."
      describe_app
      kill "$pid"
      sleep 10
      kill -9 "$pid" 2> /dev/null
      wait "$pid"
      return 124
    fi
  done
  wait "$pid"
}

run_tests "$1"
status=$?
if [ "$status" -eq 124 ] || { [ "$status" -ne 0 ] && grep -qs "Connecting to the VM Service timed out" "$output" "$results"; }; then
  echo "::warning title=Retried the Android tests::The first run never reached a test, so the run starts once more."
  run_tests "$1"
  status=$?
fi
exit "$status"
