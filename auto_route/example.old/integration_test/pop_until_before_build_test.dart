import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/restorable_app.dart';

// popUntil called before the navigator has built the pages it closes did
// nothing, and the pages stayed: right after a push in the same frame, and
// as an app the platform ended and restored starts.
// Headless tests: auto_route/test/simple_router/pop_until_before_build_test.dart
// and auto_route/test/restoration/restore_then_pop_until_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('pop until before build', () {
    RootStackRouter buildRouter() => .build(
      routes: [
        AutoRoute(path: '/', page: namedPage('HomeRoute'), initial: true),
        AutoRoute(path: '/list', page: namedPage('ListRoute')),
        AutoRoute(path: '/detail', page: namedPage('DetailRoute')),
      ],
    );

    // Steps: open Home, push List and Detail, and in the same frame pop
    // until the first page.
    // Should: Home alone is left, on screen.
    testWidgets('popUntil right after two pushes leaves the first page', (
      tester,
    ) async {
      await pumpRestorableApp(tester, buildRouter);
      final router = RestorableRouterApp.router;
      unawaited(router.push(const NamedRoute('ListRoute')));
      unawaited(router.push(const NamedRoute('DetailRoute')));
      router.popUntil((route) => route.isFirst);
      await tester.pumpAndSettle();
      expect(
        (
          tester.takeException(),
          router.stack.map((page) => page.name).join(', '),
          find.text('HomeRoute').evaluate().length,
        ),
        (null, 'HomeRoute', 1),
      );
      await expectBrowserUrl('/');
    });

    // Steps: open Home, List and Detail, let the platform end and restore
    // the app, then pop until the first page before its first frame.
    // Should: Home alone is left, on screen.
    // On a device the restored app may have only Home and List before that
    // frame, so the check needs List among the restored pages.
    // Flutter's state restoration doesn't run on the web.
    testWidgets(
      "popUntil before a restored app's first frame leaves the first page",
      (tester) async {
        await pumpRestorableApp(tester, buildRouter);
        unawaited(
          RestorableRouterApp.router.push(const NamedRoute('ListRoute')),
        );
        await tester.pumpAndSettle();
        unawaited(
          RestorableRouterApp.router.push(const NamedRoute('DetailRoute')),
        );
        await tester.pumpAndSettle();
        await tester.restartAndRestore();
        final router = RestorableRouterApp.router;
        final restored = router.stack.map((p) => p.name).take(2).join(', ');
        router.popUntil((route) => route.isFirst);
        await tester.pumpAndSettle();
        expect(
          (
            restored,
            tester.takeException(),
            router.stack.map((page) => page.name).join(', '),
            find.text('HomeRoute').evaluate().length,
          ),
          ('HomeRoute, ListRoute', null, 'HomeRoute', 1),
        );
      },
      skip: kIsWeb,
    );
  });
}
