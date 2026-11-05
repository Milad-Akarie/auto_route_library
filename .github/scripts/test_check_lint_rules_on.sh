#!/usr/bin/env bash
# Tests check_lint_rules_on.sh on two small sample repositories: a clean one,
# which must pass, and one with a rule set to false, a per-rule exclude and an
# ignore comment, which must fail and name each of them.
#
# Usage: test_check_lint_rules_on.sh

script="$(cd "$(dirname "$0")" && pwd)/check_lint_rules_on.sh"
work=$(mktemp -d) || exit 1
trap 'rm -rf "$work"' EXIT
failures=0

sample() {
  local dir=$work/$1
  mkdir -p "$dir/lib"
  git -C "$dir" init -q
  cat > "$dir/analysis_options.yaml" <<YAML
analyzer:
  exclude:
    - build/**
    - "**/*.gr.dart"
linter:
  rules:
    public_member_api_docs: true
dart_code_metrics:
  metrics-exclude:
    - test/**
  exclude:
    - build/**
  rules:
    - avoid-unused-parameters: true
YAML
  echo 'void main() {}' > "$dir/lib/main.dart"
  # A generated file may carry ignores.
  printf '// ignore_for_file: type=lint\n' > "$dir/lib/router.gr.dart"
}

check() {
  local name=$1 want=$2
  shift 2
  local output status
  output=$("$script" "$work/$name")
  status=$?
  if [ "$status" -ne "$want" ]; then
    echo "FAIL $name: exit $status, wanted $want"
    failures=$((failures + 1))
  fi
  for expected in "$@"; do
    if ! grep -qF -- "$expected" <<<"$output"; then
      echo "FAIL $name: output lacks '$expected'"
      failures=$((failures + 1))
    fi
  done
  [ "$failures" -eq 0 ] && echo "PASS $name"
}

sample clean
git -C "$work/clean" add -A

sample dirty
cat >> "$work/dirty/analysis_options.yaml" <<YAML
    - prefer-trailing-comma: false
    - avoid-returning-widgets:
        exclude: [test/**]
YAML
sed -i.bak 's/public_member_api_docs: true/public_member_api_docs: false/' "$work/dirty/analysis_options.yaml"
rm "$work/dirty/analysis_options.yaml.bak"
printf 'void main() {\n  // ignore: avoid_print\n  print(1);\n}\n' > "$work/dirty/lib/main.dart"
git -C "$work/dirty" add -A

check clean 0
check dirty 1 \
  'analysis_options.yaml:7: rule public_member_api_docs is set to false' \
  'rule prefer-trailing-comma is set to false' \
  'a rule has its own exclude' \
  'lib/main.dart:2: ignore comment:'

[ "$failures" -eq 0 ] || exit 1
