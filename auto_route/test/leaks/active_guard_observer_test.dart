import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'disposal_tracker.dart';

/// Lets the navigation through once [release] completes.
class _HeldGuard extends AutoRouteGuard {
  final release = Completer<void>();

  @override
  Future<void> onNavigation(NavigationResolver resolver, StackRouter router) async {
    await release.future;
    resolver.next();
  }
}

PageInfo _page(String name) => .new(name, builder: (_) => Text(name));

RootStackRouter _buildRouter({List<AutoRouteGuard> childGuards = const []}) => .build(
  routes: [
    AutoRoute(path: '/', page: _page('HomeRoute')),
    AutoRoute(
      path: '/host',
      page: PageInfo('HostRoute', builder: (_) => const AutoRouter()),
      children: [
        AutoRoute(path: '', page: _page('FirstChildRoute')),
        AutoRoute(path: 'second', page: _page('SecondChildRoute'), guards: childGuards),
      ],
    ),
  ],
);

void main() {
  // Steps: push HostRoute, whose page holds an AutoRouter, then pop it.
  // Happened: the nested router's ActiveGuardObserver stayed undisposed, one
  // more on each visit.
  // Should: disposing the nested router disposes it.
  testWidgets('Popping a nested router disposes its ActiveGuardObserver', (tester) async {
    final router = _buildRouter();
    await pumpRouterApp(tester, router);
    final observers = DisposalTracker<ActiveGuardObserver>();
    unawaited(router.pushPath('/host'));
    await tester.pumpAndSettle();
    expect(find.text('FirstChildRoute'), findsOneWidget);
    expect(observers.created, 1);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('HomeRoute'), findsOneWidget);
    expect(observers.undisposed, 0);
  });

  // Steps: in HostRoute's nested router, push SecondChildRoute, whose guard
  // waits; pop HostRoute meanwhile, then let the guard through.
  // Should: the guard, finishing after its router is disposed, changes
  // nothing and throws nothing.
  testWidgets('A guard that finishes after its nested router is disposed throws nothing', (tester) async {
    final guard = _HeldGuard();
    final router = _buildRouter(childGuards: [guard]);
    await pumpRouterApp(tester, router);
    final observers = DisposalTracker<ActiveGuardObserver>();
    unawaited(router.pushPath('/host'));
    await tester.pumpAndSettle();
    final nested = router.innerRouterOf<StackRouter>('HostRoute')!;
    unawaited(nested.push(const NamedRoute('SecondChildRoute')));
    await tester.pump();
    expect(nested.activeGuardObserver.guardInProgress, isTrue);

    router.pop();
    await tester.pumpAndSettle();
    expect(observers.undisposed, 0);
    guard.release.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('HomeRoute'), findsOneWidget);
  });
}
