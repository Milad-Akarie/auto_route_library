#!/usr/bin/env bash
# Prints the test files of one shard of the headless tests, one per line.
#
# `flutter test --total-shards` splits the tests, not the files, so every
# shard still loads every file. In Chrome, loading a file costs about 4.6 s
# on CI and running its tests next to nothing, so those shards each took as
# long as the whole suite. This splits the files instead: sorted by path, the
# shard takes every <total>-th one starting at its index, so each directory's
# files spread over all shards. Together the shards take every file once.
#
# Usage, from auto_route: test_files_for_shard.sh <shard index> <total shards>

set -euo pipefail

index=$1
total=$2
if ! [[ "$index" =~ ^[0-9]+$ && "$total" =~ ^[0-9]+$ ]] || [ "$index" -ge "$total" ]; then
  echo "Usage: test_files_for_shard.sh <shard index> <total shards>, with 0 <= index < total" >&2
  exit 2
fi

files=$(find test -name '*_test.dart' | LC_ALL=C sort | awk -v total="$total" -v shard="$index" '(NR - 1) % total == shard')
# flutter test with no file runs them all, so an empty shard is an error.
if [ -z "$files" ]; then
  echo "Shard $index of $total has no test files." >&2
  exit 1
fi
echo "$files"
