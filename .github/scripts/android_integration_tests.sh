#!/usr/bin/env bash
# Runs one half of the example app's integration tests on emulator-5554.
#
# Once the app has started, flutter test gives itself a fixed 5 s to connect
# to the app's VM Service, through adb's port forward. On a loaded runner that
# sometimes runs out before any test starts, while the other half, with the
# same app on the same kind of runner, connects at once. So a run that fails
# that way runs once more; the app is already built, so the retry costs little.
#
# Usage, from auto_route/example: android_integration_tests.sh <shard index>
# The results and the output go to $RUNNER_TEMP, as the report step expects.

set -o pipefail

run_tests() {
  flutter test --reporter github --file-reporter "json:$RUNNER_TEMP/test-results.json" \
    integration_test/all_tests.dart --total-shards 2 --shard-index "$1" -d emulator-5554 2>&1 |
    tee "$RUNNER_TEMP/test-output.txt"
}

run_tests "$1"
status=$?
if [ "$status" -ne 0 ] && grep -q "Connecting to the VM Service timed out" "$RUNNER_TEMP/test-output.txt"; then
  echo "::warning title=Retried the Android tests::flutter test timed out connecting to the app's VM Service before any test ran, so the run starts once more."
  run_tests "$1"
  status=$?
fi
exit "$status"
