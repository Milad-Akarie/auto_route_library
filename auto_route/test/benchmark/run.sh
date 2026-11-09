#!/bin/sh
# Runs a benchmark several times and summarizes the runs.
#
#   test/benchmark/run.sh <benchmark> <runs> <output folder> [device]
#
# <benchmark> is one of:
#   url         test/benchmark/url_benchmark_test.dart on the VM
#   url-chrome  the same, in Chrome
#   navigation  the example app's integration_test/navigation_benchmark.dart,
#               in profile mode on [device]: macos (the default) or a phone's id
#
# Each run's output goes to <output folder>/<benchmark>-<n>.txt, after a
# `LOAD` line with the Mac's load averages when it started: other test runs on
# the same Mac skew the url benchmark's timings. A phone times the navigation
# benchmark itself, so the Mac's load doesn't skew those. Then tool/summarize_benchmark.dart
# prints the table of medians and spreads. Run it from auto_route/. To judge a
# change of the url benchmark on a busy Mac, run compare.sh instead.
set -eu

benchmark=$1
runs=$2
out=$3
device=${4:-macos}
mkdir -p "$out"

i=1
while [ "$i" -le "$runs" ]; do
  file="$out/$benchmark-$i.txt"
  echo "LOAD $(sysctl -n vm.loadavg)" > "$file"
  case $benchmark in
    url) flutter test --run-skipped test/benchmark/url_benchmark_test.dart >> "$file" 2>&1 ;;
    url-chrome) flutter test --run-skipped test/benchmark/url_benchmark_test.dart --platform chrome >> "$file" 2>&1 ;;
    navigation)
      (cd example.old && flutter drive --profile --no-dds --driver=test_driver/perf_driver.dart \
        --target=integration_test/navigation_benchmark.dart -d "$device") >> "$file" 2>&1 ;;
    *) echo "Unknown benchmark: $benchmark" >&2; exit 64 ;;
  esac
  grep -q RESULT "$file" || { echo "Run $i printed no results; see $file" >&2; exit 1; }
  i=$((i + 1))
done

dart run tool/summarize_benchmark.dart "$out/$benchmark"-*.txt
