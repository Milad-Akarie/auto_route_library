import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// Pop then back doesn't return to the popped page.
// https://github.com/Milad-Akarie/auto_route_library/issues/1839
// Also covers https://github.com/Milad-Akarie/auto_route_library/issues/2069,
// the same bug seen through the browser's back button.
// Headless tests: auto_route/test/simple_router/pop_and_back_test.dart (native)
// and auto_route/test/web/pop_and_back_web_test.dart (web).
//
// The first two tests count the native history's entries, so they're skipped
// on web, where back() walks the browser's own history; the last two run only
// on web and check the browser's address bar instead.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() => router = buildSimpleRouter());

  // Steps: start on FirstRoute, navigate to SecondRoute, then to
  // ThirdRoute, pop ThirdRoute, then call back() from SecondRoute.
  // Should: back() lands on FirstRoute, not on the ThirdRoute just popped.
  testWidgets(
    'Popping then going back does not return to the popped page',
    (tester) async {
      await pumpRouterApp(tester, router);
      expectCurrentPage(router, FirstRoute.name);
      expect(router.urlState.url, '/');

      unawaited(router.navigate(const SecondRoute()));
      await tester.pumpAndSettle();
      expectCurrentPage(router, SecondRoute.name);
      expect(router.navigationHistory.length, 2);

      unawaited(router.navigate(const ThirdRoute()));
      await tester.pumpAndSettle();
      expectCurrentPage(router, ThirdRoute.name);
      expect(router.navigationHistory.length, 3);

      router.pop();
      await tester.pumpAndSettle();
      expectCurrentPage(router, SecondRoute.name);
      expect(router.navigationHistory.length, 2);
      expect(router.urlState.url, '/second-route');

      router.back();
      await tester.pumpAndSettle();
      expectCurrentPage(router, FirstRoute.name);
      expect(router.stack.map((p) => p.name), [FirstRoute.name]);
      expect(router.navigationHistory.length, 1);
      expect(router.urlState.url, '/');
      expect(router.canNavigateBack, isFalse);
    },
    skip: kIsWeb,
  );

  // Steps: pushAll SecondRoute and ThirdRoute (only the last one gets a
  // history entry), pop ThirdRoute, then call back().
  // Should: back() lands on FirstRoute.
  testWidgets(
    'Popping a page pushed with pushAll then going back does not return to it',
    (tester) async {
      await pumpRouterApp(tester, router);
      unawaited(router.pushAll([const SecondRoute(), const ThirdRoute()]));
      await tester.pumpAndSettle();
      expectCurrentPage(router, ThirdRoute.name);
      expect(router.navigationHistory.length, 2);

      router.pop();
      await tester.pumpAndSettle();
      expectCurrentPage(router, SecondRoute.name);
      expect(router.navigationHistory.length, 2);
      expect(router.urlState.url, '/second-route');

      router.back();
      await tester.pumpAndSettle();
      expectCurrentPage(router, FirstRoute.name);
      expect(router.stack.map((p) => p.name), [FirstRoute.name]);
      expect(router.navigationHistory.length, 1);
    },
    skip: kIsWeb,
  );

  // Steps on web: navigate to SecondRoute, then to ThirdRoute, pop ThirdRoute,
  // then call back() from SecondRoute.
  // Should: the browser steps back over ThirdRoute's entry, so back() lands on
  // FirstRoute and the address bar shows '/'.
  testWidgets(
    'On web, popping then going back does not return to the popped page',
    (tester) async {
      await pumpRouterAppWithConfig(tester, router);
      unawaited(router.navigate(const SecondRoute()));
      await tester.pumpAndSettle();
      await expectBrowserUrl('/second-route');
      unawaited(router.navigate(const ThirdRoute()));
      await tester.pumpAndSettle();
      await expectBrowserUrl('/third-route');

      router.pop();
      await tester.pumpAndSettle();
      await expectBrowserUrl('/second-route');
      expectCurrentPage(router, SecondRoute.name);

      router.back();
      await expectBrowserUrl('/');
      await tester.pumpAndSettle();
      expectCurrentPage(router, FirstRoute.name);
    },
    skip: !kIsWeb,
  );

  // Steps on web (#2069): push SecondRoute, push ThirdRoute, maybePop from
  // ThirdRoute, then press the browser's back button.
  // Should: the browser goes straight to FirstRoute, not through ThirdRoute
  // again.
  testWidgets(
    'On web, maybePop then the browser back button goes to the page before',
    (tester) async {
      await pumpRouterAppWithConfig(tester, router);
      unawaited(router.push(const SecondRoute()));
      await tester.pumpAndSettle();
      unawaited(router.push(const ThirdRoute()));
      await tester.pumpAndSettle();
      await expectBrowserUrl('/third-route');

      await router.maybePop();
      await tester.pumpAndSettle();
      await expectBrowserUrl('/second-route');

      pressBrowserBack();
      await expectBrowserUrl('/');
      await tester.pumpAndSettle();
      expectCurrentPage(router, FirstRoute.name);
      expect(router.stack.map((p) => p.name), [FirstRoute.name]);
    },
    skip: !kIsWeb,
  );
}
