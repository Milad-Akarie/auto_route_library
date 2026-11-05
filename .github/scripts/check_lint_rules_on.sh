#!/usr/bin/env bash
# Fails if a lint rule is switched off, excluded or ignored. Every analyzer and
# DCM rule stays on; a finding is fixed in code.
#
# It lists each place where
#   - a rule is set to `false` under `linter: rules:` or
#     `dart_code_metrics: rules:` in a tracked analysis_options.yaml,
#   - a rule under `dart_code_metrics: rules:` has its own `exclude:`,
#   - a tracked Dart file has an `// ignore:` or `// ignore_for_file:` comment.
# Generated files (*.gr.dart, *.g.dart, *.mocks.dart) are skipped. The top-level
# `exclude:` lists for build output and generated code, and `metrics-exclude:`,
# are left alone.
#
# Usage, from anywhere inside the repository:
# check_lint_rules_on.sh [folder]
# `folder` defaults to the repository root; only files tracked by git under it
# are read.

cd "${1:-$(git rev-parse --show-toplevel)}" || exit 1

options_program='
  function indent(s) { match(s, /^ */); return RLENGTH }
  FNR == 1 { section = ""; in_rules = 0 }
  /^[[:space:]]*(#.*)?$/ { next }
  {
    depth = indent($0)
    if (depth == 0) {
      section = ($0 ~ /^linter:/) ? "linter" : ($0 ~ /^dart_code_metrics:/) ? "dcm" : ""
      in_rules = 0
      next
    }
    if (section == "") next
    if (depth == 2) { in_rules = ($0 ~ /^  rules:/); next }
    if (!in_rules) next
    line = $0
    sub(/^[[:space:]]*(- )?/, "", line)
    if (line ~ /^[A-Za-z0-9_-]+:[[:space:]]*false[[:space:]]*(#.*)?$/) {
      name = line; sub(/:.*/, "", name)
      printf "OFF %s:%d: rule %s is set to false\n", FILENAME, FNR, name
    } else if (section == "dcm" && line ~ /^exclude:/) {
      printf "EXCLUDE %s:%d: a rule has its own exclude\n", FILENAME, FNR
    }
  }
'

found=$(
  {
    git ls-files -z -- '*analysis_options.yaml' | xargs -0 awk "$options_program"
    git ls-files -z -- '*.dart' ':!:*.gr.dart' ':!:*.g.dart' ':!:*.mocks.dart' |
      xargs -0 grep -HnE '//[[:space:]]*ignore(_for_file)?:' |
      sed -E 's/^/IGNORE /; s/^(IGNORE [^:]*:[0-9]+:)/\1 ignore comment:/'
  } 2>/dev/null
)

if [ -z "$found" ]; then
  echo "Every lint rule is on and nothing is ignored."
  exit 0
fi

echo "$found" | sed -E 's/^(OFF|EXCLUDE|IGNORE) //'
echo
echo "A rule switched off: $(echo "$found" | grep -c '^OFF ')"
echo "Per-rule excludes:   $(echo "$found" | grep -c '^EXCLUDE ')"
echo "Ignore comments:     $(echo "$found" | grep -c '^IGNORE ')"
echo "Fix the code instead: no rule may be switched off, excluded or ignored."
exit 1
