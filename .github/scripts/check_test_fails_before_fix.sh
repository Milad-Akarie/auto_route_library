#!/usr/bin/env bash
# Checks that a fix commit's headless test fails without the fix and passes
# with it, so the test proves the fix rather than passing either way.
#
# Makes a detached worktree at the commit's parent and copies in every file
# under auto_route/test/ or auto_route_generator/test/ that the commit added
# or changed, support files included. Runs the test files among them there
# (`flutter test` from auto_route/, in Chrome for files marked
# `@TestOn('browser')`, and `dart test` from auto_route_generator/),
# then checks out the commit in the same worktree and runs them again. A test
# that passes on the VM before the fix is run in Chrome too, since its bug
# may be one the web alone has.
#
# Usage, from anywhere in the repository:
# check_test_fails_before_fix.sh <commit>
#
# Prints the tests that failed, then one verdict on its last line:
#   VERDICT: fails before, passes after
#   VERDICT: fails to compile before, the fix adds <names>
#   VERDICT: fails to compile before, the fix does not add <names>
#   VERDICT: passes before: the test proves nothing
#   VERDICT: fails after
#   VERDICT: no headless test
# A compile failure before counts only when the fix adds the API the test
# calls: the second form. The third needs a person to read why it fails.
#
# Exits 0 for "fails before, passes after" and for a compile failure the fix
# explains, 1 for any other verdict, and 2 when it can't run. Each test run
# stops after CHECK_TEST_TIMEOUT seconds (default 900). The worktree is made
# in a temporary folder and removed on exit.

set -u

commit_arg=${1:-}
if [ -z "$commit_arg" ]; then
  echo "Usage: check_test_fails_before_fix.sh <commit>" >&2
  exit 2
fi

root=$(git rev-parse --show-toplevel) || exit 2
commit=$(git -C "$root" rev-parse --verify --quiet "$commit_arg^{commit}") || {
  echo "Not a commit: $commit_arg" >&2
  exit 2
}
parent=$(git -C "$root" rev-parse --verify --quiet "$commit^") || {
  echo "The commit has no parent: $commit_arg" >&2
  exit 2
}
timeout_seconds=${CHECK_TEST_TIMEOUT:-900}

echo "Commit: $(git -C "$root" log -1 --format='%h %s' "$commit")"

changed_files() {
  git -C "$root" diff --name-only --diff-filter=AMR "$parent" "$commit" -- "$@"
}

test_files=()
while IFS= read -r file; do
  test_files+=("$file")
done < <(changed_files auto_route/test auto_route_generator/test)

headless_tests=()
for file in "${test_files[@]+"${test_files[@]}"}"; do
  case "$file" in
    *_test.dart) headless_tests+=("$file") ;;
  esac
done

if [ ${#headless_tests[@]} -eq 0 ]; then
  integration=$(changed_files auto_route/example.old/integration_test)
  if [ -n "$integration" ]; then
    echo "Only integration tests changed:"
    echo "$integration"
  else
    echo "The commit adds or changes no test."
  fi
  echo "VERDICT: no headless test"
  exit 1
fi

work=$(mktemp -d "${TMPDIR:-/tmp}/fails_before_fix.XXXXXX") || exit 2
worktree="$work/tree"
log="$work/log"

cleanup() {
  git -C "$root" worktree remove --force "$worktree" >/dev/null 2>&1
  rm -rf "$work"
}

# Removes the worktree and exits with the given code.
finish() {
  cleanup
  trap - EXIT
  exit "$1"
}
trap cleanup EXIT
trap 'finish 130' INT TERM

if ! git -C "$root" worktree add --detach --quiet "$worktree" "$parent"; then
  echo "Could not make a worktree at $parent." >&2
  finish 2
fi

# Copies the commit's version of every changed test file into the worktree.
copy_tests() {
  local file
  for file in "${test_files[@]}"; do
    mkdir -p "$worktree/$(dirname "$file")"
    git -C "$root" show "$commit:$file" >"$worktree/$file" || return 1
  done
}

# Runs a command with a time limit, through perl's alarm, which macOS has.
with_timeout() {
  perl -e 'alarm shift; exec @ARGV or die "exec: $!"' "$timeout_seconds" "$@"
}

# Runs test files of one package folder: `dart test` for the generator,
# `flutter test` for auto_route, with `--platform chrome` for files marked
# `@TestOn('browser')`, which never run on the VM. Prints nothing; appends
# the output to $log and returns the test command's exit code.
run_package() {
  local package=$1 platform=$2
  shift 2
  local relative=() file
  for file in "$@"; do
    relative+=("${file#"$package"/}")
  done
  (
    cd "$worktree/$package" || exit 2
    flutter pub get >/dev/null 2>&1 || flutter pub get || exit 2
    case "$platform" in
      dart) with_timeout dart test "${relative[@]}" ;;
      chrome) with_timeout flutter test --platform chrome "${relative[@]}" ;;
      *) with_timeout flutter test "${relative[@]}" ;;
    esac
  ) >>"$log" 2>&1
}

# Runs every changed test file at the worktree's current checkout. Returns 0
# when all pass. With web_too=1, also runs the VM's files in Chrome, except
# files marked `@TestOn('vm')`, as CI runs every headless test in both.
web_too=0
run_tests() {
  : >"$log"
  local vm_tests=() browser_tests=() generator_tests=() file status=0
  for file in "${headless_tests[@]}"; do
    case "$file" in
      auto_route_generator/*) generator_tests+=("$file") ;;
      *)
        if grep -q "^@TestOn('browser')" "$worktree/$file"; then
          browser_tests+=("$file")
        else
          vm_tests+=("$file")
          if [ "$web_too" = 1 ] && ! grep -q "^@TestOn('vm')" "$worktree/$file"; then
            browser_tests+=("$file")
          fi
        fi
        ;;
    esac
  done
  if [ ${#vm_tests[@]} -gt 0 ]; then
    run_package auto_route vm "${vm_tests[@]}" || status=1
  fi
  if [ ${#browser_tests[@]} -gt 0 ]; then
    run_package auto_route chrome "${browser_tests[@]}" || status=1
  fi
  if [ ${#generator_tests[@]} -gt 0 ]; then
    run_package auto_route_generator dart "${generator_tests[@]}" || status=1
  fi
  return "$status"
}

# Prints the failing tests and compile errors from the last run, briefly.
show_failures() {
  grep -E '\[E\]$|Failed to load|Error: |error - |No tests ran' "$log" | sort -u | head -40
}

# A browser test that throws while loading also says "Failed to load", so
# only the compiler's own messages count.
compile_failed() {
  grep -qE 'Compilation failed|\.dart:[0-9]+:[0-9]+: Error: ' "$log"
}

# Names the compile errors say are missing, one per line.
missing_names() {
  grep -oE "(getter|setter|method|Method|name|type|class|parameter|constructor|operator|member|function)( not found)?:? '[A-Za-z_$][A-Za-z0-9_$.]*'|'[A-Za-z_$][A-Za-z0-9_$]*' (isn't|is not) (defined|a type)|No named parameter with the name '[A-Za-z_$][A-Za-z0-9_$]*'|Undefined name '[A-Za-z_$][A-Za-z0-9_$]*'|Couldn't find constructor '[A-Za-z_$][A-Za-z0-9_$.]*'" "$log" |
    grep -oE "'[^']+'" | tr -d "'" | sed 's/.*\.//' | sort -u
}

echo "Tests: ${headless_tests[*]}"
echo
echo "Before the fix, at $(git -C "$root" rev-parse --short "$parent"):"
copy_tests || finish 2
# A test that passes on the VM may be a test of a web-only bug: try Chrome.
if run_tests && { web_too=1; echo "Passes on the VM; running in Chrome too."; run_tests; }; then
  before=pass
elif compile_failed; then
  before=compile
else
  before=fail
fi
show_failures
names=""
[ "$before" = compile ] && names=$(missing_names)

echo
echo "With the fix, at $(git -C "$root" rev-parse --short "$commit"):"
if ! git -C "$worktree" checkout --force --detach --quiet "$commit"; then
  echo "Could not check out $commit." >&2
  finish 2
fi
if run_tests; then
  after=pass
else
  after=fail
fi
show_failures
echo

if [ "$after" = fail ]; then
  echo "VERDICT: fails after"
  finish 1
fi
case "$before" in
  pass)
    echo "VERDICT: passes before: the test proves nothing"
    finish 1
    ;;
  fail)
    echo "VERDICT: fails before, passes after"
    finish 0
    ;;
esac

# The test fails to compile before the fix. It counts only when the fix
# adds every missing name in the package code it changes, or exports a file
# that declares it.
added=$(git -C "$root" diff "$parent" "$commit" -- '*/lib/*' | grep -E '^\+[^+]')
while IFS= read -r exported; do
  [ -n "$exported" ] || continue
  added+=$'\n'$(git -C "$root" show "$commit:auto_route/lib/$exported" 2>/dev/null)
done < <(grep -oE "^\+export '[^:']+'" <<<"$added" | sed -E "s/^\+export '//; s/'$//")
not_added=()
found=()
while IFS= read -r name; do
  [ -n "$name" ] || continue
  if grep -qw -- "$name" <<<"$added"; then
    found+=("$name")
  else
    not_added+=("$name")
  fi
done <<<"$names"

if [ ${#not_added[@]} -eq 0 ] && [ ${#found[@]} -gt 0 ]; then
  echo "VERDICT: fails to compile before, the fix adds ${found[*]}"
  finish 0
fi
echo "VERDICT: fails to compile before, the fix does not add ${not_added[*]:-the missing names (none found in the errors)}"
finish 1
