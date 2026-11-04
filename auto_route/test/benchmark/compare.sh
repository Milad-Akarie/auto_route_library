#!/bin/sh
# Compares the url benchmark at an earlier commit with the working tree.
#
#   test/benchmark/compare.sh <benchmark> <runs> <before commit> <output folder>
#
# <benchmark> is url (the VM) or url-chrome. The before and after runs take
# turns, before first, so a busy Mac slows both alike. Each run's output goes
# to <output folder>/before/ or <output folder>/after/, as run.sh writes it.
# Then summarize.dart prints each case's median before and after, the change,
# and the larger spread; a change inside the spread is noise. The before commit
# must have the benchmark. Run it from auto_route/.
set -eu

benchmark=$1
runs=$2
before=$3
here=$(pwd)
mkdir -p "$4/before" "$4/after"
out=$(cd "$4" && pwd)
tree="$out/before-tree"

git worktree add --detach "$tree" "$before" > /dev/null
trap 'git -C "$here" worktree remove --force "$tree"' EXIT
(cd "$tree/auto_route" && flutter pub get > /dev/null)

i=1
while [ "$i" -le "$runs" ]; do
  (cd "$tree/auto_route" && "$here/test/benchmark/run.sh" "$benchmark" 1 "$out/before/$i" > /dev/null)
  mv "$out/before/$i/$benchmark-1.txt" "$out/before/$benchmark-$i.txt"
  test/benchmark/run.sh "$benchmark" 1 "$out/after/$i" > /dev/null
  mv "$out/after/$i/$benchmark-1.txt" "$out/after/$benchmark-$i.txt"
  rmdir "$out/before/$i" "$out/after/$i"
  i=$((i + 1))
done

dart run test/benchmark/summarize.dart "$out/before/$benchmark"-*.txt --vs "$out/after/$benchmark"-*.txt
