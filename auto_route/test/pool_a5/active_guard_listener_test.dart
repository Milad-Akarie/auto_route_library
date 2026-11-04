import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

class _HeldGuard extends AutoRouteGuard {
  final release = Completer<void>();

  @override
  Future<void> onNavigation(NavigationResolver resolver, StackRouter router) async {
    await release.future;
    resolver.next();
  }
}

// https://github.com/Milad-Akarie/auto_route_library/issues/1121
// Steps: add a listener to router.activeGuardObserver, then push a route
// whose guard waits.
// Reported: the listener never runs.
// Should: it runs when the guard starts and again when it finishes.
void main() {
  testWidgets('activeGuardObserver tells its listeners when a guard starts and ends', (tester) async {
    final guard = _HeldGuard();
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const Text('Home')),
        ),
        AutoRoute(
          path: '/guarded',
          page: PageInfo('GuardedRoute', builder: (_) => const Text('Guarded')),
          guards: [guard],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    final seen = <bool>[];
    router.activeGuardObserver.addListener(() => seen.add(router.activeGuardObserver.guardInProgress));

    unawaited(router.pushPath('/guarded'));
    await tester.pump();
    expect(seen, [true]);
    expect(router.activeGuardObserver.activeGuards, [guard]);

    guard.release.complete();
    await tester.pumpAndSettle();
    expect(seen, [true, false]);
    expect(find.text('Guarded'), findsOneWidget);
  });
}
