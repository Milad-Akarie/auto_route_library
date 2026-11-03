# auto_route fork: rules and how a fix is proven

This repository is its own product: a maintained fork of the auto_route package. It sends no pull requests and opens no issues upstream. A fix is merged only once tests prove it here, on every platform; CI runs them again on every push.

## Rules
1. One issue is one commit. Its tests and its fix land together in a single commit named after the issue, `fix: <what users see> (#N)`, with the cause in the body. An integration test added later for an issue already fixed is its own commit: `test: integration test for <what> (#N)`.
2. If fixing an issue breaks something somewhere else, fix that as a separate issue, in its own commit.
3. Finish the whole job yourself. Make the decisions and say in the report what was decided and why. Stop only for something that would go live, or for data that can't be restored.
4. A new issue found along the way goes to its own chat, on a model that fits its difficulty, with these rules passed on. First check that no chat is on it already.
5. Before solving an issue, check whether other issues are similar or rest on the same groundwork. Do the groundwork first, in its own commit, then each issue on top, one commit each.
6. No pull requests and no new issues upstream. `Co-authored-by` trailers for code taken from others stay.

Also: never push (the maintainer merges into `master` and pushes), format only the lines you add, American English, made-up names in code and fixtures.

## Proving a fix
1. A headless test in `auto_route/test/` that fails before the fix and passes after it. Its comment names the issue and the steps.
2. An integration test in `auto_route/example/integration_test/`, one file per fix, that drives the example app through the same steps. Add the file to `integration_test/all_tests.dart`; that file runs every test in one app launch.
3. Run here, from `auto_route/` for the headless tests:

   ```bash
   flutter test
   ```

   ```bash
   flutter test --platform chrome
   ```

   Then from `auto_route/example/` for the integration tests, on macOS, the Pixel_9 emulator and the iOS simulator:

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

4. The local runs in step 3 must pass before merge. CI (`.github/workflows/tests.yml`) runs the same checks on every push, as the backstop: analyze, the headless tests on the VM and in Chrome, and the integration tests on Android, iOS, web and macOS. A CI failure on `master` is fixed as its own issue.

If a test fails on one platform because of a real bug, skip it on that platform only, with a comment naming the issue and the platform, and give that bug its own chat (rule 4).

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
- `flutter pub get` and builds rewrite generated files that are tracked. Never commit them; restore them from the repo root:

  ```bash
  git checkout -- auto_route/example/ios/Flutter/ephemeral/flutter_native_integration.env auto_route/example/macos/Flutter/ephemeral
  ```

- Test files on master aren't formatter-clean. Format only the files you add: `dart format <file>`.
