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
    _canLeave.value = false;
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/'),
        AutoRoute(page: _FormRoute.page, path: '/form'),
        AutoRoute(page: _LegacyFormRoute.page, path: '/legacy-form'),
        AutoRoute(page: _ToggleFormRoute.page, path: '/toggle-form'),
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

  // flutter/flutter#174674: each refused exit added a browser entry, so the
  // browser's back button then took one press per refusal.
  // Push a page whose PopScope refuses, press the browser's back button three
  // times, then let the page go and press it once more: FirstRoute shows, on
  // the entry it had. The same with the three refusals from the app's own
  // back, maybePop.
  for (final fromApp in [false, true]) {
    testWidgets('Refused exits on web add no browser entries, refused from the app: $fromApp', (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);
      final start = browserSerialCount;
      unawaited(router.push(const _ToggleFormRoute()));
      await settleBrowser(tester);

      for (var i = 0; i < 3; i++) {
        if (fromApp) {
          await router.maybePop();
          await settleBrowser(tester);
        } else {
          await pressBrowserBackOn(tester, router);
        }
        expectCurrentPage(router, _ToggleFormRoute.name);
        expect(browserSerialCount, start + 1);
      }
      expect(_popAttempts, 3);

      _canLeave.value = true;
      await tester.pump();
      await pressBrowserBack(tester);
      expectCurrentPage(router, FirstRoute.name);
      expect(router.stack.map((p) => p.name), [FirstRoute.name]);
      expect(browserPath, '/');
      expect(browserSerialCount, start);
    });
  }
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

final ValueNotifier<bool> _canLeave = ValueNotifier(false);

class _ToggleFormRoute extends PageRouteInfo<void> {
  const _ToggleFormRoute() : super(name);

  static const String name = 'ToggleFormRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => ValueListenableBuilder(
      valueListenable: _canLeave,
      builder: (_, canLeave, _) => PopScope(
        canPop: canLeave,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _popAttempts++;
        },
        child: const Scaffold(body: Text(name)),
      ),
    ),
  );
}
