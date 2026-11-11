import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// pushAndPopUntil with a predicate that is always false leaves only the new
// page.
// https://github.com/Milad-Akarie/auto_route_library/issues/2015
// Headless test: auto_route/test/web/push_and_pop_until_web_test.dart (web).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('push and pop until', () {
    late RootStackRouter router;
    setUp(() => router = buildSimpleRouter());

    // Steps: push SecondRoute, push ThirdRoute, then pushAndPopUntil FirstRoute
    // with a predicate that is always false.
    // Should: only FirstRoute is left and there is no history to go back to.
    testWidgets(
      'pushAndPopUntil with a false predicate leaves only the new page',
      (tester) async {
        await pumpRouterApp(tester, router);
        unawaited(router.push(const SecondRoute()));
        await tester.pumpAndSettle();
        unawaited(router.push(const ThirdRoute()));
        await tester.pumpAndSettle();

        unawaited(
          router.pushAndPopUntil(const FirstRoute(), predicate: (_) => false),
        );
        await tester.pumpAndSettle();
        expectCurrentPage(router, FirstRoute.name);
        expect(router.stack.map((p) => p.name), [FirstRoute.name]);
        expect(router.canPop(), isFalse);
      },
      skip: kIsWeb,
    );

    // Steps on web: the same, then press the browser's back button.
    // Should: the address bar shows '/' and FirstRoute stays; no removed page
    // returns.
    testWidgets(
      'On web, the browser back button after pushAndPopUntil does not bring a '
      'removed page back',
      (tester) async {
        await pumpRouterAppWithConfig(tester, router);
        unawaited(router.push(const SecondRoute()));
        await tester.pumpAndSettle();
        unawaited(router.push(const ThirdRoute()));
        await tester.pumpAndSettle();
        await expectBrowserUrl('/third-route');

        unawaited(
          router.pushAndPopUntil(const FirstRoute(), predicate: (_) => false),
        );
        await tester.pumpAndSettle();
        await expectBrowserUrl('/');

        pressBrowserBack();
        await expectBrowserUrl('/');
        await tester.pumpAndSettle();
        expectCurrentPage(router, FirstRoute.name);
        expect(router.stack.map((p) => p.name), [FirstRoute.name]);
      },
      skip: !kIsWeb,
    );
  });
}
