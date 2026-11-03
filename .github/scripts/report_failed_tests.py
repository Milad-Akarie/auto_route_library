"""Names each failed test of a `flutter test` run in GitHub's public annotations.

Reads the results file that `flutter test --file-reporter json:<path>` writes
and prints one `::error` line per failed or errored test, load errors and
setUpAll/tearDownAll errors included, with the first lines of each error.
When no test failed, as when the app didn't build, it prints the last lines
of the run's saved output instead. Writes the same to the job summary when
$GITHUB_STEP_SUMMARY is set. Annotations and the summary can be read without
signing in, unlike the logs.

Usage: python3 report_failed_tests.py <results.json> [<root> [<output.txt>]]
Run it from the directory `flutter test` ran in. Test files are named
relative to <root>, the current directory by default. <output.txt> is what
the run printed, saved with `| tee`.
"""

import json
import os
import re
import sys

# How many lines of each error the annotation keeps.
ERROR_LINES = 8

# How many of the run's last output lines the annotation keeps when no test failed.
OUTPUT_LINES = 40

ANSI_ESCAPE = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")


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


def report_output(results_path, output_path, root):
    """Names a run that failed outside any test by the last lines it printed."""
    if not output_path or not os.path.exists(output_path):
        # Tests didn't run, for example because an earlier step failed.
        print(f"No failed test found in {results_path}, and no saved output.")
        return
    with open(output_path, encoding="utf-8", errors="replace") as output:
        lines = [ANSI_ESCAPE.sub("", line.rstrip()) for line in output]
    last_lines = "\n".join(lines[-OUTPUT_LINES:]).replace(root + os.sep, "")
    title = "No test failed: the build or the run did. Its last lines"
    print(f"::error title={escape_property(title)}::{escape_data(last_lines)}")
    write_summary(["## The build or the run failed", "", "````text", last_lines, "````", ""])


def write_summary(lines):
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary_path:
        with open(summary_path, "a", encoding="utf-8") as out:
            out.write("\n".join(lines) + "\n")


def main():
    if not 2 <= len(sys.argv) <= 4:
        sys.exit(__doc__)
    path = sys.argv[1]
    root = os.path.abspath(sys.argv[2] if len(sys.argv) >= 3 else ".")
    output_path = sys.argv[3] if len(sys.argv) == 4 else None
    # A missing or empty results file means no test ran: the app didn't build,
    # or the device never started.
    failures = read_failures(path) if os.path.exists(path) else []
    if not failures:
        report_output(path, output_path, root)
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
    write_summary(summary)


if __name__ == "__main__":
    main()
