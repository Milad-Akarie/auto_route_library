# Contributing

This repository is a maintained fork of auto_route. Report bugs and send pull requests here.

## Branches

Branch from `dev` and open your pull request against `dev`. `master` holds stable releases, and each release has a `release/<version>` branch, such as `release/12.6.0`, that apps can pin to.

## Before you change code

Reproduce the bug first: the reporter's setup, platform, steps and, when they matter, versions. Read every comment on
the issue. If it turns out to be intended behavior, a misuse or already answered, change no code and say why on the
issue.

## One issue, one commit

An issue's fix and its tests land in one commit, named after what users see:

```
fix: replace() rejected by a guard keeps the page it would replace (#2046)
```

Put the cause in the commit body.

## Proving a fix

1. A headless test in `auto_route/test/` that fails before the fix and passes after it. Its comment names the issue and
   the steps. For a fix in the code generator, the test goes in `auto_route_generator/test/`, built on
   `test/support/generate.dart`.
2. An integration test in `auto_route/example.old/integration_test/`, one file per fix, added to
   `integration_test/all_tests.dart`.

## Before you open a pull request

Run these from `auto_route/`:

```bash
flutter analyze
```

```bash
flutter test
```

```bash
flutter test --platform chrome
```

Run the integration tests from `auto_route/example.old/` on the platform your change touches, or on macOS when it
touches every platform:

```bash
flutter test integration_test/all_tests.dart -d macos
```

If you changed the generator, run its tests from `auto_route_generator/`:

```bash
dart test
```

From the repository root, check that no lint rule was switched off:

```bash
bash .github/scripts/check_lint_rules_on.sh
```

Run `dart format` on every file you change. Add a line for your change under `## Unreleased` in the package's
`CHANGELOG.md`.

## Lint findings

Fix a finding in code. Don't switch a rule off, exclude a file or add an ignore comment; the check above lists the few
exceptions the project allows.

## Style

- American English in code, comments and commits.
- Made-up names in code and fixtures, never a real person's.

## Using AI tools

They're welcome. Read the [AI policy](AI_POLICY.md) first: you answer for every line and every claim in your pull request, whoever wrote it, and you say which tool you used.

## Security

Report a vulnerability privately, as [SECURITY.md](SECURITY.md) says, not in a public issue.
