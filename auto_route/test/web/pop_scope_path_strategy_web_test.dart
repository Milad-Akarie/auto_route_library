@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' show window;

import '../main_router.dart';
import '../router_test_utils.dart';
import 'browser_history.dart';
import 'pop_scope_web_test.dart' show pressBrowserBackOn;

// https://github.com/flutter/flutter/issues/82660
// With the path url strategy (urls without '#'), the browser's back button
// did not reach WillPopScope. Push a page whose PopScope refuses, then press
// the browser's back button: the page stays and PopScope hears of the attempt.
void main() {
  useRealBrowserHistory();
  usePathUrlStrategy();

  late RootStackRouter router;
  setUp(() async {
    _attempts = 0;
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/'),
        AutoRoute(page: _FormRoute.page, path: '/form'),
      ],
    );
    await rewindBrowserHistory();
  });

  testWidgets('PopScope blocks the browser back button under the path url strategy', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    unawaited(router.push(const _FormRoute()));
    await settleBrowser(tester);
    expect(browserPath, '/form');
    // The address bar shows a path, not a '#' url.
    expect(window.location.hash, isEmpty);
    expect(window.location.pathname, endsWith('/form'));

    await pressBrowserBackOn(tester, router);
    expectCurrentPage(router, _FormRoute.name);
    expect(_attempts, 1);
    expect(browserPath, '/form', reason: 'after pressBrowserBackOn(tester, router)');
    expect(window.location.pathname, endsWith('/form'), reason: 'after pressBrowserBackOn(tester, router)');
  });
}

int _attempts = 0;

class _FormRoute extends PageRouteInfo<void> {
  const _FormRoute() : super(name);

  static const String name = 'PathFormRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _attempts++;
      },
      child: const Scaffold(body: Text(name)),
    ),
  );
}
