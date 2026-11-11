#!/usr/bin/env bash
# Runs the code generator from each folder someone might run it in, and fails
# if any committed `.gr.dart` file changes, disappears or appears.
#
# A build from auto_route/ used to build the example's files too, as part of
# auto_route, and rewrote the example's six routers to empty. auto_route's
# build.yaml now leaves example/ and example.old/ to the example's own build.
#
# Usage, from the repository root, once `flutter pub get` has run there:
# check_generated_routers.sh
# A failure leaves the changed files in place, for `git diff` to show.

root=$(git rev-parse --show-toplevel) || exit 1
cd "$root" || exit 1

changed_routers() {
  git status --porcelain -- '*.gr.dart'
}

if [ -n "$(changed_routers)" ]; then
  echo "::error title=Routers already changed::Commit or restore these .gr.dart files first:"
  changed_routers
  exit 1
fi

check_build() {
  local folder=$1
  shift
  local command="dart run build_runner build${*:+ $*}"
  echo "Building from $folder: $command"
  if ! (cd "$folder" && dart run build_runner build "$@"); then
    echo "::error title=Build failed::$command failed in $folder."
    exit 1
  fi
  if [ -n "$(changed_routers)" ]; then
    echo "::error title=Routers changed::$command in $folder changed committed routers:"
    changed_routers
    git diff --stat -- '*.gr.dart'
    exit 1
  fi
}

check_build auto_route
check_build auto_route/example.old
check_build . --workspace
echo "Every committed router regenerated unchanged."
