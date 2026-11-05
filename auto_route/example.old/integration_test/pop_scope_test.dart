import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// PopScope blocks the browser's back button.
// https://github.com/Milad-Akarie/auto_route_library/issues/1944
// https://github.com/Milad-Akarie/auto_route_library/issues/1588
// Headless test: auto_route/test/web/pop_scope_web_test.dart
//
// Runs only on web, the one platform with a browser back button.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('pop scope', () {
    late RootStackRouter router;
    setUp(() {
      _popAttempts = 0;
      router = RootStackRouter.build(
        routes: [
          AutoRoute(page: FirstRoute.page, path: '/'),
          AutoRoute(page: _FormRoute.page, path: '/form'),
        ],
      );
    });

    // Steps: push a page wrapped in PopScope(canPop: false), then press the
    // browser's back button.
    // Should: the page stays, PopScope hears of the attempt, and the browser
    // returns to the page's entry.
    testWidgets(
      'PopScope blocks the browser back button',
      (tester) async {
        await pumpRouterAppWithConfig(tester, router);
        unawaited(router.push(const _FormRoute()));
        await tester.pumpAndSettle();
        await expectBrowserUrl('/form');
        final formEntry = browserEntryIndex();

        pressBrowserBack();
        await _waitForPopAttempt(tester);
        await expectBrowserUrl('/form');
        expect(browserEntryIndex(), formEntry);
        expect(router.current.name, _FormRoute.name);
      },
      skip: !kIsWeb,
    );
  });
}

var _popAttempts = 0;

// The browser reports the back step through an engine message; wait until the
// page hears of it.
Future<void> _waitForPopAttempt(WidgetTester tester) async {
  for (var i = 0; i < 20 && _popAttempts == 0; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
  expect(_popAttempts, 1, reason: 'the page heard of the pop attempt');
  await tester.pumpAndSettle();
}

class _FormRoute extends PageRouteInfo<void> {
  const new() : super(name);

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
