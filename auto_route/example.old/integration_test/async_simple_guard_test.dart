import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A guard re-check waits for an async AutoRouteGuard.simple callback that is
// still running, instead of calling it a second time.
// Found while fixing the guard issues, no upstream issue.
// Headless test: auto_route/test/guards/async_simple_guard_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: open the app with reevaluateListenable set on '/profile', guarded by
  // an async simple guard that waits before it calls resolver.next(). Fire the
  // listenable while the guard waits, then let the guard go on.
  // Should: the guard ran once, nothing failed and ProfileRoute is on top.
  testWidgets(
    'a guard re-check waits for an async simple guard still running',
    (tester) async {
      var guardCalls = 0;
      final release = Completer<void>();
      final auth = ValueNotifier(0);
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
          ),
          NamedRouteDef(
            name: 'ProfileRoute',
            path: '/profile',
            guards: [
              AutoRouteGuard.simple((resolver, _) async {
                guardCalls++;
                await release.future;
                resolver.next();
              }),
            ],
            builder: (_, _) => const Scaffold(body: Text('ProfileRoute')),
          ),
        ],
      );
      await pumpRouterConfigApp(
        tester,
        router.config(
          reevaluateListenable: auth,
          deepLinkBuilder: (link) =>
              link.initial ? const DeepLink.path('/profile') : link,
        ),
      );

      auth.value++;
      await tester.pump();
      release.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(guardCalls, 1);
      expect(router.topRoute.name, 'ProfileRoute');
      expect(find.text('ProfileRoute'), findsOneWidget);
      await expectBrowserUrl('/profile');
    },
  );
}
