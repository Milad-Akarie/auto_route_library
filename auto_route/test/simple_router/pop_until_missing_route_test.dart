import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import '../named_page.dart';
import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1502
  // popUntilRouteWithName with a name no page in the stack has popped every
  // page and left a blank screen.
  // Steps: stack [Page1Route, Page2Route], then popUntilRouteWithName or
  // popUntilRouteWithPath for a page that isn't there, scoped or not.
  // Should: the first page stays on screen.
  RootStackRouter buildRouter() => .build(
    routes: [
      NamedRouteDef(name: 'Page1Route', path: '/', builder: (_, _) => const NamedPage('Page1Route')),
      NamedRouteDef(name: 'Page2Route', path: '/page2', builder: (_, _) => const NamedPage('Page2Route')),
      NamedRouteDef.shell(
        name: 'ShellRoute',
        path: '/shell',
        children: [
          NamedRouteDef(name: 'Inner1Route', path: '', builder: (_, _) => const NamedPage('Inner1Route')),
          NamedRouteDef(name: 'Inner2Route', path: 'inner2', builder: (_, _) => const NamedPage('Inner2Route')),
        ],
      ),
    ],
  );

  for (final scoped in [true, false]) {
    testWidgets('popUntilRouteWithName for a missing page keeps the first page (scoped: $scoped)', (tester) async {
      final router = buildRouter();
      await pumpRouterApp(tester, router);
      unawaited(router.push(const NamedRoute('Page2Route')));
      await tester.pumpAndSettle();

      router.popUntilRouteWithName('Page3Route', scoped: scoped);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(router.stack.map((p) => p.name), ['Page1Route']);
      expect(find.text('Page1Route'), findsOneWidget);
    });

    testWidgets('popUntilRouteWithPath for a missing page keeps the first page (scoped: $scoped)', (tester) async {
      final router = buildRouter();
      await pumpRouterApp(tester, router);
      unawaited(router.push(const NamedRoute('Page2Route')));
      await tester.pumpAndSettle();

      router.popUntilRouteWithPath('/page3', scoped: scoped);
      await tester.pumpAndSettle();

      expect(router.stack.map((p) => p.name), ['Page1Route']);
      expect(find.text('Page1Route'), findsOneWidget);
    });
  }

  testWidgets('popUntilRouteWithName in a nested router for a missing page keeps its first page', (tester) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router, initialLink: '/shell/inner2');
    final inner = router.innerRouterOf<StackRouter>('ShellRoute')!;
    expect(inner.stack.map((p) => p.name), ['Inner1Route', 'Inner2Route']);

    inner.popUntilRouteWithName('Page3Route');
    await tester.pumpAndSettle();

    expect(inner.stack.map((p) => p.name), ['Inner1Route']);
    expect(find.text('Inner1Route'), findsOneWidget);
  });

  testWidgets('popUntilRouteWithName, not scoped, still finds a page of the parent router', (tester) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push(const NamedRoute('Page2Route')));
    await tester.pumpAndSettle();
    unawaited(router.navigatePath('/shell/inner2'));
    await tester.pumpAndSettle();
    expect(router.stack.map((p) => p.name), ['Page1Route', 'Page2Route', 'ShellRoute']);

    router.innerRouterOf<StackRouter>('ShellRoute')!.popUntilRouteWithName('Page2Route', scoped: false);
    await tester.pumpAndSettle();

    expect(router.stack.map((p) => p.name), ['Page1Route', 'Page2Route']);
    expect(find.text('Page2Route'), findsOneWidget);
  });
}
