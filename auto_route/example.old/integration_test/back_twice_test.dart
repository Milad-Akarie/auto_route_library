import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// router.back() twice in a row goes back two pages, and a page pushed after a
// back() gets its own history entry. No upstream issue matches.
// Headless test: auto_route/test/simple_router/back_twice_test.dart.
//
// The history length is the native history's, so it's checked only off web,
// where back() walks the browser's own history; there the test waits for the
// address bar after each step instead.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('back twice', () {
    late RootStackRouter router;
    setUp(() => router = buildSimpleRouter());

    Future<void> pushSecondThenThird(WidgetTester tester) async {
      await pumpRouterAppWithConfig(tester, router);
      unawaited(router.push(const SecondRoute()));
      await tester.pumpAndSettle();
      await expectBrowserUrl('/second-route');
      unawaited(router.push(const ThirdRoute()));
      await tester.pumpAndSettle();
      await expectBrowserUrl('/third-route');
      expectCurrentPage(router, ThirdRoute.name);
      if (!kIsWeb) expect(router.navigationHistory.length, 3);
    }

    // Steps: start on FirstRoute, push SecondRoute, push ThirdRoute, then call
    // back() twice.
    // Should: the first back() lands on SecondRoute, the second on FirstRoute.
    testWidgets('Calling back() twice goes back two pages', (tester) async {
      await pushSecondThenThird(tester);

      router.back();
      await expectBrowserUrl('/second-route');
      await tester.pumpAndSettle();
      expectCurrentPage(router, SecondRoute.name);
      expect(router.canNavigateBack, isTrue);

      router.back();
      await expectBrowserUrl('/');
      await tester.pumpAndSettle();
      expectCurrentPage(router, FirstRoute.name);
      expect(router.stack.map((p) => p.name), [FirstRoute.name]);
      expect(router.urlState.url, '/');
      if (!kIsWeb) expect(router.navigationHistory.length, 1);
    });

    // Steps: start on FirstRoute, push SecondRoute, push ThirdRoute, call
    // back(), push ThirdRoute again, then call back().
    // Should: the second ThirdRoute is recorded, so back() lands on
    // SecondRoute.
    testWidgets('A page pushed after back() is recorded in the history', (
      tester,
    ) async {
      await pushSecondThenThird(tester);

      router.back();
      await expectBrowserUrl('/second-route');
      await tester.pumpAndSettle();
      expectCurrentPage(router, SecondRoute.name);

      unawaited(router.push(const ThirdRoute()));
      await tester.pumpAndSettle();
      await expectBrowserUrl('/third-route');
      expectCurrentPage(router, ThirdRoute.name);
      if (!kIsWeb) expect(router.navigationHistory.length, 3);

      router.back();
      await expectBrowserUrl('/second-route');
      await tester.pumpAndSettle();
      expectCurrentPage(router, SecondRoute.name);
      expect(router.stack.map((p) => p.name), [
        FirstRoute.name,
        SecondRoute.name,
      ]);
      if (!kIsWeb) expect(router.navigationHistory.length, 2);
    });
  });
}
