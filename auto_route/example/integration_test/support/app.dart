import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'browser_url.dart' if (dart.library.js_interop) 'browser_url_web.dart' as browser;

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
}) async {
  _bringAppToForeground(tester);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: theme,
      routeInformationParser: router.defaultRouteParser(),
      routerDelegate: router.delegate(
        reevaluateListenable: reevaluationNotifier,
        deepLinkBuilder: (_) => DeepLink.path(initialLink),
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
Future<void> pumpRouterAppWithConfig(WidgetTester tester, RootStackRouter router) {
  return pumpRouterConfigApp(
    tester,
    router.config(deepLinkBuilder: (link) => link.initial ? DeepLink.path('/') : link),
  );
}

/// Shows [config] in a [MaterialApp] and waits for its first page.
Future<void> pumpRouterConfigApp(WidgetTester tester, RouterConfig<UrlState> config) async {
  _bringAppToForeground(tester);
  await tester.pumpWidget(MaterialApp.router(routerConfig: config));
  await tester.pumpAndSettle();
}

// The test binding forgets the app's lifecycle state after each test, and
// while it's unknown Flutter stops telling Android whether it handles back
// (see systemBack). A running app is in the foreground.
void _bringAppToForeground(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
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
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      await const MethodChannel('auto_route_example/system_back').invokeMethod<void>('pressBack');
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

/// Swipes from the left edge of the screen, the iOS back gesture.
Future<void> swipeBack(WidgetTester tester) async {
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  await tester.dragFrom(Offset(2, size.height / 2), Offset(size.width * 0.8, 0));
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
