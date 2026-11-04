@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' show WindowEventGetters, window;

import '../main_router.dart';
import '../router_test_utils.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();

  late RootStackRouter router;
  setUp(() async {
    _popAttempts = 0;
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/'),
        AutoRoute(page: _FormRoute.page, path: '/form'),
        AutoRoute(page: _LegacyFormRoute.page, path: '/legacy-form'),
      ],
    );
    await rewindBrowserHistory();
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1944
  // Push a page wrapped in PopScope(canPop: false), then press the browser's
  // back button.
  // The page should stay, as it does for the system back button, the browser
  // should return to its entry, and PopScope should hear of the attempt.
  testWidgets('PopScope on web blocks the browser back button', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    unawaited(router.push(const _FormRoute()));
    await settleBrowser(tester);
    final formEntry = browserSerialCount;

    await pressBrowserBackOn(tester, router);
    expectCurrentPage(router, _FormRoute.name);
    expect(_popAttempts, 1);
    expect(browserPath, '/form');
    expect(browserSerialCount, formEntry);

    // An in-app back step that the page allows still works afterwards.
    router.removeLast();
    await settleBrowser(tester);
    expectCurrentPage(router, FirstRoute.name);
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1588
  // The same with the older WillPopScope, whose onWillPop returns false.
  testWidgets('WillPopScope on web blocks the browser back button', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    unawaited(router.push(const _LegacyFormRoute()));
    await settleBrowser(tester);
    final formEntry = browserSerialCount;

    await pressBrowserBackOn(tester, router);
    expectCurrentPage(router, _LegacyFormRoute.name);
    expect(_popAttempts, 1);
    expect(browserPath, '/legacy-form');
    expect(browserSerialCount, formEntry);
  });
}

var _popAttempts = 0;

/// Presses the browser's back button and waits until the app has answered it:
/// by following the browser, which changes the app's url, or by refusing,
/// which moves the browser forward again.
Future<void> pressBrowserBackOn(WidgetTester tester, RootStackRouter router) async {
  final answered = Completer<void>();
  void onAnswer() {
    if (!answered.isCompleted) answered.complete();
  }

  // Both listen before the press: the app may follow the browser at once.
  router.navigationHistory.addListener(onAnswer);
  final stepBackAndForward = window.onPopState.take(2).toList().then((_) => onAnswer());
  window.history.back();
  await answered.future;
  router.navigationHistory.removeListener(onAnswer);
  stepBackAndForward.ignore();
  await settleBrowser(tester);
}

class _FormRoute extends PageRouteInfo<void> {
  const _FormRoute() : super(name);

  static const String name = 'FormRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _popAttempts++;
      },
      child: const Scaffold(body: Text(name)),
    ),
  );
}

class _LegacyFormRoute extends PageRouteInfo<void> {
  const _LegacyFormRoute() : super(name);

  static const String name = 'LegacyFormRoute';
  static PageInfo page = PageInfo(
    name,
    // #1588 reports the deprecated WillPopScope, which apps still use.
    // ignore: deprecated_member_use
    builder: (_) => WillPopScope(
      onWillPop: () async {
        _popAttempts++;
        return false;
      },
      child: const Scaffold(body: Text(name)),
    ),
  );
}
