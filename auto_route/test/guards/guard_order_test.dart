import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// Pins the README section "The order guards run in", under Route Guards:
// a stack router runs the root router's global guards first, then the route's
// own, each in the order listed; each guard waits for the one before it to
// answer, and the first one that rejects stops the rest. A route with
// children is checked before its children, and each child goes through the
// global guards again. The guards of tab routes run without the global
// guards.
// Steps: an app whose root router has a global guard, an Admin route with two
// guards and a guarded child Users, and a Tabs route whose second tab is
// guarded. Navigate to Admin with Users, then to the tabs and their second
// tab, writing down each guard as it runs.
void main() {
  late List<String> calls;
  setUp(() => calls = []);

  AutoRouteGuard logging(String name, {bool shouldLetIn = true}) =>
      .simple((resolver, _) {
        calls.add('$name ${resolver.routeName}');
        shouldLetIn ? resolver.next() : resolver.reject();
      });

  RootStackRouter buildRouter({
    required AutoRouteGuard global,
    AutoRouteGuard? adminGuard,
  }) => .build(
    guards: [global],
    routes: [
      AutoRoute(page: _page('Home'), path: '/', initial: true),
      AutoRoute(
        page: PageInfo('Admin', builder: (_) => const AutoRouter()),
        path: '/admin',
        guards: [adminGuard ?? logging('admin'), logging('audit')],
        children: [
          AutoRoute(
            page: _page('Users'),
            path: 'users',
            guards: [logging('users')],
          ),
        ],
      ),
      AutoRoute(
        page: PageInfo('Tabs', builder: (_) => const AutoTabsRouter()),
        path: '/tabs',
        children: [
          AutoRoute(page: _page('Feed'), path: 'feed'),
          AutoRoute(
            page: _page('Profile'),
            path: 'profile',
            guards: [logging('profile')],
          ),
        ],
      ),
    ],
  );

  const toAdminUsers = PageRouteInfo<void>(
    'Admin',
    initialChildren: [PageRouteInfo<void>('Users')],
  );

  testWidgets('Global guards, then own guards, parent before child', (
    tester,
  ) async {
    final router = buildRouter(global: logging('auth'));
    await pumpRouterApp(tester, router);
    calls.clear();

    unawaited(router.navigate(toAdminUsers));
    await tester.pumpAndSettle();

    expect(calls, [
      'auth Admin',
      'admin Admin',
      'audit Admin',
      'auth Users',
      'users Users',
    ]);
    expect(find.text('Users'), findsOneWidget);
  });

  testWidgets('A guard runs only once the guard before it has answered', (
    tester,
  ) async {
    final authAnswer = Completer<void>();
    final router = buildRouter(
      global: .simple((resolver, _) async {
        calls.add('auth ${resolver.routeName}');
        if (resolver.routeName == 'Admin') await authAnswer.future;
        resolver.next();
      }),
    );
    await pumpRouterApp(tester, router);
    calls.clear();

    unawaited(router.navigate(toAdminUsers));
    await tester.pumpAndSettle();
    final callsWhileWaiting = List.of(calls);
    authAnswer.complete();
    await tester.pumpAndSettle();

    expect(callsWhileWaiting, ['auth Admin']);
    expect(calls, [
      'auth Admin',
      'admin Admin',
      'audit Admin',
      'auth Users',
      'users Users',
    ]);
  });

  testWidgets('The first guard that rejects stops the guards after it', (
    tester,
  ) async {
    final router = buildRouter(
      global: logging('auth'),
      adminGuard: logging('admin', shouldLetIn: false),
    );
    await pumpRouterApp(tester, router);
    calls.clear();

    unawaited(router.navigate(toAdminUsers));
    await tester.pumpAndSettle();

    expect(calls, ['auth Admin', 'admin Admin']);
    expectTopPage(router, 'Home');
  });

  testWidgets('The guards of a tab route run without the global guards', (
    tester,
  ) async {
    final router = buildRouter(global: logging('auth'));
    await pumpRouterApp(tester, router);
    calls.clear();

    unawaited(router.navigate(const PageRouteInfo<void>('Tabs')));
    await tester.pumpAndSettle();
    final callsOnOpen = List.of(calls);
    router.innerRouterOf<TabsRouter>('Tabs')!.setActiveIndex(1);
    await tester.pumpAndSettle();

    expect(callsOnOpen, ['auth Tabs']);
    expect(calls, ['auth Tabs', 'profile Profile']);
    expect(find.text('Profile'), findsOneWidget);
  });
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
