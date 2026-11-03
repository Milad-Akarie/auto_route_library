"""Names each failed test of a `flutter test` run in GitHub's public annotations.

Reads the results file that `flutter test --file-reporter json:<path>` writes
and prints one `::error` line per failed or errored test, load errors and
setUpAll/tearDownAll errors included, with the first lines of each error.
Writes the same list to the job summary when $GITHUB_STEP_SUMMARY is set.
Annotations and the summary can be read without signing in, unlike the logs.

Usage: python3 report_failed_tests.py <results.json> [<root>]
Run it from the directory `flutter test` ran in. Test files are named
relative to <root>, the current directory by default.
"""

import json
import os
import sys

# How many lines of each error the annotation keeps.
ERROR_LINES = 8


def escape_data(text):
    return text.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def escape_property(text):
    return escape_data(text).replace(":", "%3A").replace(",", "%2C")


def read_failures(path):
    """Returns (file, test name, error) for each failed test, in run order."""
    suites = {}
    tests = {}
    errors = {}
    failed = []
    with open(path, encoding="utf-8") as results:
        for line in results:
            line = line.strip()
            if not line.startswith("{"):
                continue
            event = json.loads(line)
            kind = event.get("type")
            if kind == "suite":
                suites[event["suite"]["id"]] = event["suite"].get("path") or ""
            elif kind == "testStart":
                tests[event["test"]["id"]] = event["test"]
            elif kind == "error":
                test_id = event["testID"]
                if test_id not in errors:
                    errors[test_id] = []
                    failed.append(test_id)
                errors[test_id].append(event.get("error") or "")
            elif kind == "testDone" and event.get("result") != "success":
                if event["testID"] not in errors:
                    errors[event["testID"]] = []
                    failed.append(event["testID"])
    failures = []
    for test_id in failed:
        test = tests.get(test_id, {})
        file = suites.get(test.get("suiteID"), "")
        name = test.get("name") or "(unknown test)"
        error = "\n\n".join(errors[test_id]).strip() or "(no error message)"
        failures.append((file, name, error))
    return failures


def main():
    if len(sys.argv) not in (2, 3):
        sys.exit(__doc__)
    path = sys.argv[1]
    root = os.path.abspath(sys.argv[2] if len(sys.argv) == 3 else ".")
    if not os.path.exists(path):
        # Tests didn't run, for example because an earlier step failed.
        print(f"No test results at {path}.")
        return
    failures = read_failures(path)
    if not failures:
        print(f"::error title=Tests failed::No failed test found in {path}; the run failed outside a test.")
        return
    summary = ["## Failed tests", ""]
    for file, name, error in failures:
        if file:
            file = os.path.relpath(os.path.abspath(file), root)
        # Load errors name the file by its absolute path; the checkout's path is noise.
        title = (f"{file}: {name}" if file else name).replace(root + os.sep, "")
        first_lines = "\n".join(error.splitlines()[:ERROR_LINES]).replace(root + os.sep, "")
        print(f"::error title={escape_property(title)}::{escape_data(first_lines)}")
        summary += [f"### {title}", "", "````text", first_lines, "````", ""]
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary_path:
        with open(summary_path, "a", encoding="utf-8") as out:
            out.write("\n".join(summary) + "\n")


if __name__ == "__main__":
    main()
