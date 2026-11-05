import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../centered_named_page.dart';
import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1643
  // A dialog route sits behind a guard, and reevaluateListenable fires when the
  // user's information changes. The app updates the user, which starts the
  // reevaluation, then calls router.pop() at once to close the dialog.
  // The dialog closed and opened again: the reevaluation had collected the stack
  // before the pop and pushed the dialog back once its guard called next().
  // A page popped while guards are reevaluated must stay closed.
  for (final guardDelay in [Duration.zero, const Duration(milliseconds: 50)]) {
    testWidgets('A dialog popped right after a reevaluation starts stays closed, guard delay $guardDelay (#1643)', (
      tester,
    ) async {
      final user = ValueNotifier(0);
      addTearDown(user.dispose);
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(name: 'HomeRoute', path: '/', builder: (_, _) => const CenteredNamedPage('HomeRoute')),
          NamedRouteDef(
            name: 'DialogRoute',
            path: '/dialog',
            type: RouteType.custom(opaque: false, barrierDismissible: true),
            guards: [
              AutoRouteGuard.simple((resolver, _) async {
                if (guardDelay > .zero) await Future<void>.delayed(guardDelay);
                resolver.next();
              }),
            ],
            builder: (_, _) => const CenteredNamedPage('DialogRoute'),
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
    });
  }

  // https://github.com/Milad-Akarie/auto_route_library/issues/1643
  // The same dialog, popped a frame later: the reevaluation has already
  // collected the stack and is waiting on the dialog's guard when the app pops
  // the dialog. The dialog must stay closed once the guard lets it through.
  testWidgets('A dialog popped while its guard is reevaluated stays closed (#1643)', (tester) async {
    final user = ValueNotifier(0);
    addTearDown(user.dispose);
    var guardRuns = 0;
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(name: 'HomeRoute', path: '/', builder: (_, _) => const CenteredNamedPage('HomeRoute')),
        NamedRouteDef(
          name: 'DialogRoute',
          path: '/dialog',
          type: RouteType.custom(opaque: false, barrierDismissible: true),
          guards: [
            AutoRouteGuard.simple((resolver, _) async {
              // The first run opens the dialog; the reevaluation's run waits.
              if (guardRuns++ > 0) await Future<void>.delayed(const Duration(milliseconds: 50));
              resolver.next();
            }),
          ],
          builder: (_, _) => const CenteredNamedPage('DialogRoute'),
        ),
      ],
    );
    await pumpRouterApp(tester, router, reevaluationNotifier: user);
    unawaited(router.push(const NamedRoute('DialogRoute')));
    await tester.pumpAndSettle();
    expectTopPage(router, 'DialogRoute');

    user.value++;
    await tester.pump();
    expect(guardRuns, 2, reason: 'the reevaluation is waiting on the guard');
    router.pop();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(router.stack.map((e) => e.routeData.name), ['HomeRoute']);
    expect(find.text('DialogRoute'), findsNothing);
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1785
  // The reporter's app: HomeRoute's guard calls resolver.next(), then pushes
  // AppGuardRoute when the settings say the app is locked and that route isn't
  // active. reevaluateListenable is a stream of the settings, so locking the
  // app opens AppGuardRoute. When the app is unlocked, a listener of the same
  // settings pops AppGuardRoute.
  // The dialog closed and opened again at once, as in #1643.
  testWidgets('A dialog popped by a listener of the reevaluation stream stays closed (#1785)', (tester) async {
    final isAppGuarded = ValueNotifier(false);
    addTearDown(isAppGuarded.dispose);
    final settings = StreamController<bool>.broadcast();
    addTearDown(settings.close);
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          guards: [
            AutoRouteGuard.simple((resolver, guardedRouter) {
              resolver.next();
              if (isAppGuarded.value && !guardedRouter.isRouteActive('AppGuardRoute')) {
                unawaited(guardedRouter.push(const NamedRoute('AppGuardRoute')));
              }
            }),
          ],
          builder: (_, _) => const CenteredNamedPage('HomeRoute'),
        ),
        NamedRouteDef(
          name: 'AppGuardRoute',
          path: '/locked',
          type: RouteType.custom(opaque: false),
          builder: (_, _) => const CenteredNamedPage('AppGuardRoute'),
        ),
      ],
    );
    final reevaluation = ReevaluateListenable.stream(settings.stream);
    addTearDown(reevaluation.dispose);
    await pumpRouterApp(tester, router, reevaluationNotifier: reevaluation);
    isAppGuarded.value = true;
    settings.add(true);
    await tester.pumpAndSettle();
    expect(router.stack.map((e) => e.routeData.name), ['HomeRoute', 'AppGuardRoute']);
    final unlockListener = settings.stream.listen((guarded) {
      if (!guarded) router.pop();
    });
    addTearDown(unlockListener.cancel);

    isAppGuarded.value = false;
    settings.add(false);
    await tester.pumpAndSettle();

    expect(router.stack.map((e) => e.routeData.name), ['HomeRoute']);
    expect(find.text('AppGuardRoute'), findsNothing);
  });
}
