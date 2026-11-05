import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/2299
// Start on InitialRoute, push FooRoute, then replaceAll([ProtectedRoute()]),
// whose guard calls resolver.reject(). In the reporter's words: "the stack
// is [] instead of [RouteA, RouteB], but RouteB is still shown", and the next
// push opened as the only page. It happened in nested routers too.
// A guard rejecting a route of the batch rejects the whole batch, as the
// maintainer put it in the issue, so the stack must stay as it was.
void main() {
  late bool isAllowed;

  Widget page(String name) => Scaffold(body: Center(child: Text(name)));

  AutoRouteGuard protectedGuard() => AutoRouteGuardCallback(
    (resolver, _) => isAllowed ? resolver.next() : resolver.reject(),
  );

  setUp(() => isAllowed = false);

  RootStackRouter buildRouter() => .build(
    routes: [
      NamedRouteDef(
        name: 'InitialRoute',
        path: '/',
        builder: (_, _) => page('InitialRoute'),
      ),
      NamedRouteDef(
        name: 'FooRoute',
        path: '/foo',
        builder: (_, _) => page('FooRoute'),
      ),
      NamedRouteDef(
        name: 'OtherRoute',
        path: '/other',
        builder: (_, _) => page('OtherRoute'),
      ),
      NamedRouteDef(
        name: 'ProtectedRoute',
        path: '/protected',
        guards: [protectedGuard()],
        builder: (_, _) => page('ProtectedRoute'),
      ),
      NamedRouteDef.shell(
        name: 'ShellRoute',
        path: '/shell',
        children: [
          NamedRouteDef(
            name: 'NestedInitialRoute',
            path: '',
            builder: (_, _) => page('NestedInitialRoute'),
          ),
          NamedRouteDef(
            name: 'NestedFooRoute',
            path: 'foo',
            builder: (_, _) => page('NestedFooRoute'),
          ),
          NamedRouteDef(
            name: 'NestedProtectedRoute',
            path: 'protected',
            guards: [protectedGuard()],
            builder: (_, _) => page('NestedProtectedRoute'),
          ),
        ],
      ),
    ],
  );

  List<String> namesOf(StackRouter router) =>
      router.stack.map((page) => page.routeData.name).toList();

  testWidgets('A replaceAll rejected by a guard keeps the stack (#2299)', (
    tester,
  ) async {
    final router = buildRouter();
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const NamedRoute('FooRoute')));
    await tester.pumpAndSettle();

    unawaited(router.replaceAll([const NamedRoute('ProtectedRoute')]));
    await tester.pumpAndSettle();
    expect(namesOf(router), ['InitialRoute', 'FooRoute']);
    expectTopPage(router, 'FooRoute');
    expect(router.urlState.url, '/foo');

    // The next push opens on top of the kept stack, not as the only page.
    unawaited(router.push(const NamedRoute('OtherRoute')));
    await tester.pumpAndSettle();
    expect(namesOf(router), ['InitialRoute', 'FooRoute', 'OtherRoute']);
  });

  testWidgets(
    'A replaceAll with a rejected route later in the batch keeps the stack (#2299)',
    (tester) async {
      final router = buildRouter();
      await pumpRouterConfigApp(tester, router.config());

      unawaited(
        router.replaceAll([
          const NamedRoute('OtherRoute'),
          const NamedRoute('ProtectedRoute'),
        ]),
      );
      await tester.pumpAndSettle();
      expect(namesOf(router), ['InitialRoute']);
      expectTopPage(router, 'InitialRoute');
    },
  );

  testWidgets('A replaceAll accepted by its guard replaces the stack (#2299)', (
    tester,
  ) async {
    isAllowed = true;
    final router = buildRouter();
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const NamedRoute('FooRoute')));
    await tester.pumpAndSettle();

    unawaited(router.replaceAll([const NamedRoute('ProtectedRoute')]));
    await tester.pumpAndSettle();
    expect(namesOf(router), ['ProtectedRoute']);
    expectTopPage(router, 'ProtectedRoute');
  });

  testWidgets(
    'A replaceAll rejected by a guard in a nested router keeps the nested stack (#2299)',
    (tester) async {
      final router = buildRouter();
      await pumpRouterConfigApp(tester, router.config());
      unawaited(router.push(const NamedRoute('ShellRoute')));
      await tester.pumpAndSettle();
      final nested = router.innerRouterOf<StackRouter>('ShellRoute')!;
      unawaited(nested.push(const NamedRoute('NestedFooRoute')));
      await tester.pumpAndSettle();

      unawaited(nested.replaceAll([const NamedRoute('NestedProtectedRoute')]));
      await tester.pumpAndSettle();
      expect(namesOf(nested), ['NestedInitialRoute', 'NestedFooRoute']);
      expectTopPage(router, 'NestedFooRoute');
    },
  );
}
