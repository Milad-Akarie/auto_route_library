import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// A page with keepHistory: false leaves no browser entry behind.
// https://github.com/Milad-Akarie/auto_route_library/issues/1678
// https://github.com/Milad-Akarie/auto_route_library/issues/2068
// Headless test: auto_route/test/web/keep_history_web_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('keep history', () {
    late RootStackRouter router;
    setUp(() {
      router = RootStackRouter.build(
        routes: [
          AutoRoute(page: FirstRoute.page, path: '/', keepHistory: false),
          AutoRoute(page: SecondRoute.page, path: '/second'),
        ],
      );
    });

    // Steps: open FirstRoute, which has keepHistory: false, then push
    // SecondRoute.
    // Should: FirstRoute leaves the stack, and on web SecondRoute takes its
    // browser entry instead of adding one.
    testWidgets('Pushing from a page without history replaces it', (
      tester,
    ) async {
      await pumpRouterApp(tester, router);
      await expectBrowserUrl('/');
      await expectBrowserEntryAfter(0, () async {
        unawaited(router.push(const SecondRoute()));
        await tester.pumpAndSettle();
        expect(router.stack.map((p) => p.name), [SecondRoute.name]);
        await expectBrowserUrl('/second');
      });
    });

    // Steps: open FirstRoute, which has keepHistory: false, then replaceAll
    // with SecondRoute, as a splash screen does.
    // Should: on web SecondRoute takes FirstRoute's browser entry.
    testWidgets('replaceAll from a page without history replaces its entry', (
      tester,
    ) async {
      await pumpRouterApp(tester, router);
      await expectBrowserUrl('/');
      await expectBrowserEntryAfter(0, () async {
        unawaited(router.replaceAll([const SecondRoute()]));
        await tester.pumpAndSettle();
        expect(router.stack.map((p) => p.name), [SecondRoute.name]);
        await expectBrowserUrl('/second');
      });
    });
  });
}
