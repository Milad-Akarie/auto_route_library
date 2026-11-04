import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Widget;
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' show WindowEventGetters, window;

// Helpers for headless tests that run against the real browser history in Chrome.

/// Connects the test app to the browser's own history for the calling test file.
///
/// Call it first in `main()` of a file marked `@TestOn('browser')`. By default,
/// widget tests on web run with the engine ignoring platform messages and keeping
/// history in memory, so routes never reach `window.history`; this turns both off.
/// The engine handles navigation messages one after another, and on the default
/// fake clock a message still waiting when a test ends blocks every later one, so
/// this also switches the file to [LiveTestWidgetsFlutterBinding], which runs on
/// the real clock.
void useRealBrowserHistory() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();
  ui_web.TestEnvironment.setUp(
    const ui_web.TestEnvironment(forceTestFonts: true, disableFontFallbacks: true, keepSemanticsDisabledOnUpdate: true),
  );
  ui_web.debugDefaultUrlStrategyOverride = const ui_web.HashUrlStrategy();
  // The test page's url carries the runner's metadata; start the app at '/'.
  window.history.replaceState(null, '', '#/');
}

/// Moves the browser back to its first entry, which holds '/', so a test starts there.
///
/// Call it from `setUp`. Entries after the first stay as forward entries until the
/// next navigation replaces them.
Future<void> rewindBrowserHistory() async {
  final stepsBack = browserSerialCount;
  if (stepsBack <= 0) return;
  final popped = window.onPopState.first;
  window.history.go(-stepsBack);
  await popped;
}

/// The serial number the engine gives the current browser history entry.
///
/// Counts from 0 for the first entry the app wrote; -1 before the app wrote any.
int get browserSerialCount {
  final state = window.history.state.dartify();
  return state is Map ? (state['serialCount'] as num).toInt() : -1;
}

/// The app path the current browser history entry holds, such as '/second-route'.
String get browserPath => ui_web.urlStrategy!.getPath();

/// Pumps until the router settles and every route it reported is in the
/// browser history, repeating while that schedules another frame.
Future<void> settleBrowser(WidgetTester tester) async {
  do {
    await tester.pumpAndSettle();
    // The engine handles navigation messages one after another, so its reply
    // to this one comes once every route reported before it is written.
    await SystemNavigator.selectMultiEntryHistory();
  } while (tester.binding.hasScheduledFrame);
}

/// Runs [move], which moves the browser through its history, waits for the
/// browser's popstate event, and settles.
///
/// [move] is a back step from the app, such as `router.back`, or the browser's
/// own, such as `() => window.history.back()`, the call the back button makes.
Future<void> browserMove(WidgetTester tester, VoidCallback move) async {
  final popped = window.onPopState.first;
  move();
  await popped;
  await settleBrowser(tester);
}

/// Presses the browser's back button and settles.
Future<void> pressBrowserBack(WidgetTester tester) => browserMove(tester, () => window.history.back());

/// Makes the browser's current entry hold [path], as when the app is opened at
/// a deep link, and makes [path] the app's initial route.
///
/// The entry keeps the engine's serial number, so [browserSerialCount] stays
/// where it was, and is marked as the browser's until the app writes it; see
/// [appWroteBrowserEntry]. Clears the initial route when the test ends.
void openBrowserAt(WidgetTester tester, String path) {
  final dispatcher = tester.binding.platformDispatcher;
  addTearDown(dispatcher.clearDefaultRouteNameTestValue);
  dispatcher.defaultRouteNameTestValue = path;
  final serialCount = browserSerialCount < 0 ? 0 : browserSerialCount;
  window.history.replaceState(
    {'serialCount': serialCount, 'state': null, _openedByBrowser: true}.jsify(),
    '',
    '#$path',
  );
}

// Kept beside the engine's own keys: the app reads the engine's 'state' of
// the entry it starts at as the state it saved there.
const _openedByBrowser = 'openedByBrowser';

/// Whether the app has written the browser's current entry since
/// [openBrowserAt] made it, as it does when it reports its route.
bool get appWroteBrowserEntry {
  final state = window.history.state.dartify();
  return !(state is Map && state[_openedByBrowser] == true);
}

/// Shows [app] the way runApp starts an app, and settles.
///
/// runApp builds the widget tree before the first frame, and the frame comes
/// after the pending microtasks, so the Router reports the route of the
/// finished initial navigation. In a test the tree is already there, and
/// [WidgetTester.pumpWidget] builds the app inside a frame, so the Router
/// first reports the empty route of the unfinished navigation, as no app
/// started by runApp does.
Future<void> pumpAsRunApp(WidgetTester tester, Widget app) async {
  tester.binding.attachRootWidget(tester.binding.wrapWithDefaultView(app));
  tester.binding.buildOwner!.buildScope(tester.binding.rootElement!);
  await Future<void>.delayed(.zero);
  await settleBrowser(tester);
}

/// Presses the browser's forward button and settles.
Future<void> pressBrowserForward(WidgetTester tester) => browserMove(tester, () => window.history.forward());
