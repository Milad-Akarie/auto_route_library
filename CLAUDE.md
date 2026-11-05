# auto_route fork: rules and how a fix is proven

This repository is its own product: a maintained fork of the auto_route package. It sends no pull requests and opens no issues upstream. A fix is merged only once tests prove it here, on every platform; CI runs them again on every push.

## Rules
1. One issue is one commit. Its tests and its fix land together in a single commit named after the issue, `fix: <what users see> (#N)`, with the cause in the body. An integration test added later for an issue already fixed is its own commit: `test: integration test for <what> (#N)`.
2. If fixing an issue breaks something somewhere else, fix that as a separate issue, in its own commit.
3. Finish the whole job yourself. Make the decisions and say in the report what was decided and why. Stop only for something that would go live, or for data that can't be restored.
4. A new issue found along the way goes to its own chat, on a model that fits its difficulty, with these rules passed on. First check that no chat is on it already.
5. Before solving an issue, check whether other issues are similar or rest on the same groundwork. Do the groundwork first, in its own commit, then each issue on top, one commit each.
6. No pull requests and no new issues upstream. `Co-authored-by` trailers for code taken from others stay.
7. Before changing code for an issue, reproduce exactly the bug that was reported: the reporter's setup, platform, steps and, when they matter, versions. Read every comment on the issue, including the comments it links to. If the reproduction or the comments show it is intended behavior, a misuse or already answered, change no code. Commit a test that documents the behavior, or none, and say why in the report. This keeps us from fixing something that should not be fixed.

Also: never push (the maintainer merges into `dev` and pushes), run `dart format` on every file you change, American English, made-up names in code and fixtures.

The old example app lives in `auto_route/example.old/` until the new one in `auto_route/example/` takes over its tests.

## Branches
- `dev` is where work happens. Branch every piece of work from `dev`; finished work lands on `dev`.
- `master` holds stable releases. Only the maintainer moves it, when `dev` reaches a new stable.
- CI runs on every push to any branch. So the maintainer lands each finished piece on the local `dev` and pushes `dev` once, when the last piece of a batch has landed, not after each fix: CI then runs once per batch.

## Proving a fix
1. A headless test in `auto_route/test/` that fails before the fix and passes after it. Its comment names the issue and the steps.
   For a fix in the code generator, the test goes in `auto_route_generator/test/` instead, built on `test/support/generate.dart`, which runs both builders on source strings and reports whether the generated router compiles. Run it from `auto_route_generator/` with `dart test`. The committed `.gr.dart` files must then regenerate the same as before, except where the fix means to change them.
2. An integration test in `auto_route/example.old/integration_test/`, one file per fix, that drives the example app through the same steps. Add the file to `integration_test/all_tests.dart`; that file runs every test in one app launch.
3. Run here, from `auto_route/` for the headless tests:

   ```bash
   flutter test
   ```

   ```bash
   flutter test --platform chrome
   ```

   The integration tests run on all four platforms at the same time, not one after another: each platform runs from its own worktree so the builds don't clash, and a run waits only for a device that another chat's run is using. Give each chat its own ChromeDriver port (`--port=<n>` and `flutter drive --driver-port=<n>`), and use `Pixel_9_Pro_Fold` (`-port 5556`, so `emulator-5556`) when `Pixel_9` is busy. From `auto_route/example.old/`, on macOS, the Pixel_9 emulator and the iOS simulator:

   ```bash
   flutter test integration_test/all_tests.dart -d macos
   ```

   ```bash
   flutter test integration_test/all_tests.dart -d emulator-5554
   ```

   ```bash
   flutter test integration_test/all_tests.dart -d 7E32A93E-FD30-46D1-9315-AA51401A9ABA
   ```

   And on web, in headless Chrome through ChromeDriver (see Devices). Start ChromeDriver, run the tests, then stop it:

   ```bash
   ~/.cache/chromedriver/156.0.8078.80/chromedriver-mac-arm64/chromedriver --port=4444 &
   ```

   ```bash
   flutter drive --driver=test_driver/integration_test.dart --target=integration_test/all_tests.dart -d web-server --browser-name=chrome --headless
   ```

   ```bash
   pkill -f "chromedriver --port=4444"
   ```

4. Who runs what. A chat working on a change runs the headless tests (both commands above), the generator's tests when it touched the generator, analyze and DCM, the fix's tests on its parent (they must fail), and the integration tests on the platform its change touches, or on macOS when it touches every platform. The maintainer runs every step-3 run, on all four platforms and on Phil's S25 and iPhone, once per batch, on all the batch's changes together, before pushing `dev`; a failure there is traced to its commit and sent back to that change's chat. Every device run waits for its device and has a time limit. CI (`.github/workflows/tests.yml`) runs the same checks on every push, as the backstop: analyze, a check that every committed router regenerates unchanged from `auto_route/`, `auto_route/example.old/` and the root, the headless tests on the VM and in Chrome, the generator's tests, and the integration tests on Android, iOS, web and macOS. A CI failure on `dev` or `master` is fixed as its own issue.

If a test fails on one platform because of a real bug, skip it on that platform only, with a comment naming the issue and the platform, and give that bug its own chat (rule 4).

A `flutter_canary_*` test pins a Flutter bug or fix that auto_route depends on. If one fails after a Flutter upgrade, Flutter changed that behavior: don't skip it. Read its top comment, then rework or drop the workaround or report it names and the canary together, as their own issue.

## Devices
- Always pass `-d` with an emulator, simulator, `macos`, `chrome` or `web-server`. Never use a plugged-in phone. List devices with `flutter devices`.
- Android: the shared `Pixel_9`, `Pixel_9_Pro_Fold` and `Wear_OS` emulators. Never create one. Before booting one, check nothing else drives it: `pgrep -fl qemu-system` prints nothing. Boot it, then shut it down when done:

  ```bash
  ~/Library/Android/sdk/emulator/emulator -avd Pixel_9 -no-snapshot-save -no-boot-anim
  ```

  ```bash
  ~/Library/Android/sdk/platform-tools/adb -s emulator-5554 emu kill
  ```

- iOS: use the simulator that is already booted (`xcrun simctl list devices booted`) and leave it running. Never create one.
- Web: ChromeDriver 156.0.8078.80 for mac-arm64, from Google's Chrome for Testing, is at `~/.cache/chromedriver/156.0.8078.80/chromedriver-mac-arm64/chromedriver`. Its version must match the installed Chrome's; when Chrome updates itself, the matching ChromeDriver is a new download, which needs Phil's OK. Before starting it, check nothing else uses port 4444: `pgrep -f "chromedriver --port=4444"` prints nothing. Stop it when done.

## Traps
- Run `integration_test/all_tests.dart`, not the folder. On macOS the second file fails to relaunch the app, and `flutter drive` on web takes one target.
- `flutter test -d chrome` refuses integration tests. The headless test runner in Chrome never updates the address bar, so the browser url checks in `support/app.dart` prove something only under `flutter drive`.
- On Android, system back in the tests calls the activity's back handler through a channel in `MainActivity.kt`. An app can't inject a real key press into itself.
- If a test fails with "Android would close the app on back", Flutter has told Android the app doesn't handle back, so on Android 13 and later a real back would close the app. If the app should take that back, it's a real bug. It's also how a test fails when it pumps its own app and then calls `systemBack`: the test binding forgets the app's lifecycle state after every test, and Flutter sends that signal only while the state is known. Pump the app with `pumpRouterApp` or `pumpRouterConfigApp` from `support/app.dart`, which first mark it in the foreground, or call `tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed)` before `pumpWidget`.
- The repo is a Dart pub workspace of `auto_route` and `auto_route/example.old`: `flutter pub get` at the root resolves both, with one `pubspec.lock` at the root. `auto_route_generator` stays outside it and runs its own `flutter pub get`, with an override to `../auto_route` so its tests use the fork's auto_route. On Flutter 3.47.9, flutter_test pins test_api 0.7.12, and every release of package:test that allows analyzer 14, which the generator needs, requires test_api 0.7.13 or later. Once flutter_test allows that, the generator joins the workspace; the root `pubspec.yaml` says how.
