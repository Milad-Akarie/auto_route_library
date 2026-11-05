import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'browser_url.dart'
    if (dart.library.js_interop) 'browser_url_web.dart'
    as browser;

export 'browser_url.dart' if (dart.library.js_interop) 'browser_url_web.dart';

// Helpers the integration tests share, after auto_route/test/router_test_utils.dart.

/// Shows [router] in a [MaterialApp] and waits for its first page.
///
/// The app always opens at [initialLink] ('/' by default): on web the
/// browser's url would otherwise carry over from the previous test.
Future<void> pumpRouterApp(
  WidgetTester tester,
  RootStackRouter router, {
  String initialLink = '/',
  Listenable? reevaluationNotifier,
  ThemeData? theme,
  NavigatorObserversBuilder navigatorObservers =
      AutoRouterDelegate.defaultNavigatorObserversBuilder,
}) async {
  _bringAppToForeground(tester);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: theme,
      routeInformationParser: router.defaultRouteParser(),
      routerDelegate: router.delegate(
        reevaluateListenable: reevaluationNotifier,
        deepLinkBuilder: (_) => DeepLink.path(initialLink),
        navigatorObservers: navigatorObservers,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Shows [router] through its own [RootStackRouter.config], as apps do, and
/// waits for its first page.
///
/// Opens at '/' like [pumpRouterApp], but hands later links, such as the
/// browser's back steps on web, to the router unchanged.
Future<void> pumpRouterAppWithConfig(
  WidgetTester tester,
  RootStackRouter router,
) {
  return pumpRouterConfigApp(
    tester,
    router.config(
      deepLinkBuilder: (link) => link.initial ? DeepLink.defaultPath : link,
    ),
  );
}

/// Shows [config] in a [MaterialApp] and waits for its first page.
Future<void> pumpRouterConfigApp(
  WidgetTester tester,
  RouterConfig<UrlState> config,
) async {
  _bringAppToForeground(tester);
  await tester.pumpWidget(MaterialApp.router(routerConfig: config));
  await tester.pumpAndSettle();
}

/// Starts [app] at the deep link [link] the way runApp starts an app, and
/// waits for its first page.
///
/// runApp builds the widget tree before the first frame. In a test the tree
/// is already there, so pumpWidget builds the app inside a frame, where the
/// Router reports its empty route before the link's page is in. On web the
/// browser's current entry holds [link], as when the browser opens it, and
/// keeps its `browserEntryIndex`. [link] is the app's initial route until the
/// test ends.
Future<void> pumpAppAtDeepLink(
  WidgetTester tester,
  String link,
  Widget app,
) async {
  final dispatcher = tester.binding.platformDispatcher;
  addTearDown(dispatcher.clearDefaultRouteNameTestValue);
  dispatcher.defaultRouteNameTestValue = link;
  if (kIsWeb) browser.openBrowserAt(link);
  _bringAppToForeground(tester);
  tester.binding.attachRootWidget(tester.binding.wrapWithDefaultView(app));
  tester.binding.buildOwner!.buildScope(tester.binding.rootElement!);
  await tester.pumpAndSettle();
}

/// Waits until the engine has written every route reported so far to the
/// browser, then checks the app wrote the deep link's entry that
/// [pumpAppAtDeepLink] opened, still at [index], and added none after it.
///
/// Does nothing off the web, where there is no browser history.
Future<void> expectAppWroteDeepLinkEntry(int index) async {
  if (!kIsWeb) return;
  // The engine answers once it has written every route reported before.
  await SystemNavigator.selectMultiEntryHistory();
  expect(
    browser.browserEntryIndex(),
    index,
    reason: 'the browser history entry',
  );
  expect(
    browser.appWroteBrowserEntry(),
    isTrue,
    reason: 'the app reported its route',
  );
}

// The test binding forgets the app's lifecycle state after each test, and
// while it's unknown Flutter stops telling Android whether it handles back
// (see systemBack). A running app is in the foreground.
void _bringAppToForeground(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(.resumed);
}

/// Pumps frames until [finder] finds a widget, for at most [timeout], then
/// waits for the frames to stop.
///
/// For a navigation the test starts without waiting for it, such as
/// `unawaited(router.pushPath('/host'))`: the test then waits for the page
/// itself, not only for a moment with no frame scheduled. Gives up quietly at
/// [timeout], so the test's own expect reports what is missing.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final clock = Stopwatch()..start();
  while (finder.evaluate().isEmpty && clock.elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.pumpAndSettle();
}

void expectCurrentPage(StackRouter router, String name) {
  expect(router.current.name, name);
  expect(find.text(name), findsOneWidget);
}

void expectTopPage(StackRouter router, String name) {
  expect(router.topRoute.name, name);
  expect(find.text(name), findsOneWidget);
}

/// Goes back the way the platform does, then waits for the pop to finish.
///
/// On Android this calls the activity's back handler through the app's
/// MainActivity, the handler Android's back gesture and back key call, so
/// the back reaches Flutter through the Android embedding. From Android 13
/// Android calls it only while Flutter says it handles back, and otherwise
/// closes the app; the test then fails. Flutter says so only while the app is
/// in the foreground, so pump the app with [pumpRouterApp] or
/// [pumpRouterConfigApp]. Other platforms have no back key,
/// so this sends the 'popRoute' message the engine sends for one.
Future<void> systemBack(WidgetTester tester) async {
  if (!kIsWeb && defaultTargetPlatform == .android) {
    try {
      await const MethodChannel('auto_route_example/system_back')
          .invokeMethod<void>('pressBack');
    } on PlatformException catch (error) {
      if (error.code != 'appWouldClose') rethrow;
      fail('Android would close the app on back: ${error.message}');
    }
    // The back reaches Flutter as a separate platform message; give it time to arrive.
    await Future<void>.delayed(const Duration(milliseconds: 300));
  } else {
    await tester.binding.handlePopRoute();
  }
  await tester.pumpAndSettle();
}

/// Whether Android sends back to Flutter, or null off Android.
///
/// From Android 13, back reaches Flutter only while Flutter says it handles
/// back; while this is false, Android closes the app on back instead. Use it
/// where the app should close, since [systemBack] fails the test there. Pump
/// the app with [pumpRouterApp] or [pumpRouterConfigApp] first, as for
/// [systemBack].
Future<bool?> androidSendsBackToFlutter() async {
  if (kIsWeb || defaultTargetPlatform != .android) return null;
  // Flutter tells Android through a separate platform message; give it time to arrive.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  return const MethodChannel('auto_route_example/system_back')
      .invokeMethod<bool>('sendsBackToFlutter');
}

/// Swipes from the left edge of the screen, the iOS back gesture.
Future<void> swipeBack(WidgetTester tester) async {
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  await tester.dragFrom(
    Offset(2, size.height / 2),
    Offset(size.width * 0.8, 0),
  );
  await tester.pumpAndSettle();
}

/// Waits until the browser's address bar shows [expected], then checks it.
///
/// Does nothing off the web, where there is no address bar.
Future<void> expectBrowserUrl(String expected) async {
  if (!kIsWeb) return;
  // The url reaches the browser through an engine message after the frame.
  for (var i = 0; i < 20 && browser.browserUrl() != expected; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  expect(browser.browserUrl(), expected, reason: 'the browser address bar');
}

/// Waits until the browser's current history entry is [expected], as
/// [browser.browserEntryIndex] counts them, then checks it.
///
/// Does nothing off the web. Use it where the url stays the same, such as
/// going back between two pages with the same url.
Future<void> expectBrowserEntry(int expected) async {
  if (!kIsWeb) return;
  for (var i = 0; i < 20 && browser.browserEntryIndex() != expected; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  expect(
    browser.browserEntryIndex(),
    expected,
    reason: 'the browser history entry',
  );
}
