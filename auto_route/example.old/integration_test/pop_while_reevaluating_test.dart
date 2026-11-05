import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A page popped while guards are reevaluated stays closed.
// https://github.com/Milad-Akarie/auto_route_library/issues/1643
// https://github.com/Milad-Akarie/auto_route_library/issues/1785
// Headless test:
// auto_route/test/reevaluatable_router/pop_while_reevaluating_test.dart
Widget _page(String name) => Scaffold(body: SafeArea(child: Text(name)));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // https://github.com/Milad-Akarie/auto_route_library/issues/1643
  // A dialog route sits behind a guard, and reevaluateListenable fires when the
  // user's information changes. The app updates the user, which starts the
  // reevaluation, then calls router.pop() at once to close the dialog.
  // The dialog closed and opened again: the reevaluation had collected the
  // stack before the pop and pushed the dialog back once its guard called
  // next().
  // A page popped while guards are reevaluated must stay closed.
  for (final guardDelay in [Duration.zero, const Duration(milliseconds: 50)]) {
    testWidgets(
      'A dialog popped right after a reevaluation starts stays closed, guard '
      'delay $guardDelay (#1643)',
      (
        tester,
      ) async {
        final user = ValueNotifier(0);
        final router = RootStackRouter.build(
          routes: [
            NamedRouteDef(
              name: 'HomeRoute',
              path: '/',
              builder: (_, _) => _page('HomeRoute'),
            ),
            NamedRouteDef(
              name: 'DialogRoute',
              path: '/dialog',
              type: RouteType.custom(opaque: false, barrierDismissible: true),
              guards: [
                AutoRouteGuard.simple((resolver, _) async {
                  if (guardDelay > .zero) {
                    await Future<void>.delayed(guardDelay);
                  }
                  resolver.next();
                }),
              ],
              builder: (_, _) => _page('DialogRoute'),
            ),
          ],
        );
        await pumpRouterApp(tester, router, reevaluationNotifier: user);
        unawaited(router.push(const NamedRoute('DialogRoute')));
        await tester.pumpAndSettle();
        expectTopPage(router, 'DialogRoute');

        user.value++;
        router.pop();
        await tester.pumpAndSettle();
        await tester.pump(guardDelay * 2);
        await tester.pumpAndSettle();

        expect(router.stack.map((e) => e.routeData.name), ['HomeRoute']);
        expect(find.text('DialogRoute'), findsNothing);
      },
    );
  }

  // https://github.com/Milad-Akarie/auto_route_library/issues/1785
  // The reporter's app: HomeRoute's guard calls resolver.next(), then pushes
  // AppGuardRoute when the settings say the app is locked and that route isn't
  // active. reevaluateListenable is a stream of the settings, so locking the
  // app opens AppGuardRoute. When the app is unlocked, a listener of the same
  // settings pops AppGuardRoute.
  // The dialog closed and opened again at once, as in #1643.
  testWidgets(
    'A dialog popped by a listener of the reevaluation stream stays closed '
    '(#1785)',
    (tester) async {
      var isAppGuarded = false;
      final settings = StreamController<bool>.broadcast();
      addTearDown(settings.close);
      late final RootStackRouter router;
      router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            guards: [
              AutoRouteGuard.simple((resolver, router) {
                resolver.next();
                if (isAppGuarded && !router.isRouteActive('AppGuardRoute')) {
                  unawaited(router.push(const NamedRoute('AppGuardRoute')));
                }
              }),
            ],
            builder: (_, _) => _page('HomeRoute'),
          ),
          NamedRouteDef(
            name: 'AppGuardRoute',
            path: '/locked',
            type: RouteType.custom(opaque: false),
            builder: (_, _) => _page('AppGuardRoute'),
          ),
        ],
      );
      await pumpRouterApp(
        tester,
        router,
        reevaluationNotifier: ReevaluateListenable.stream(settings.stream),
      );
      isAppGuarded = true;
      settings.add(true);
      await tester.pumpAndSettle();
      expect(router.stack.map((e) => e.routeData.name), [
        'HomeRoute',
        'AppGuardRoute',
      ]);
      final unlockListener = settings.stream.listen((guarded) {
        if (!guarded) router.pop();
      });
      addTearDown(unlockListener.cancel);

      isAppGuarded = false;
      settings.add(false);
      await tester.pumpAndSettle();

      expect(router.stack.map((e) => e.routeData.name), ['HomeRoute']);
      expect(find.text('AppGuardRoute'), findsNothing);
    },
  );
}
