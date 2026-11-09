import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/2087
// Steps: Home at '/' pushes Host, which builds AutoRouter.declarative with
// the routes [A]. A has a button that calls
// AutoRouter.of(context).parent<StackRouter>()!.maybePop(), to pop the whole
// declarative router, that is Host.
// Reported: AutoRouter.of(context) did not find the declarative router, so
// parent was one level too high.
// Should: AutoRouter.of(context) in A is the declarative router, the one
// RouterScope.of(context).controller names, and the button pops Host.
void main() {
  testWidgets('AutoRouter.of finds the declarative router a page sits in', (
    tester,
  ) async {
    StackRouter? found;
    RoutingController? scopeController;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const Text('Home')),
        ),
        AutoRoute(
          path: '/host',
          page: PageInfo(
            'HostRoute',
            builder: (_) => AutoRouter.declarative(
              routes: (_) => const [PageRouteInfo('ARoute')],
            ),
          ),
          children: [
            AutoRoute(
              path: 'a',
              page: PageInfo(
                'ARoute',
                builder: (_) => Builder(
                  builder: (context) {
                    found = AutoRouter.of(context);
                    scopeController = RouterScope.of(context).controller;
                    return TextButton(
                      onPressed: () => unawaited(
                        AutoRouter.of(context)
                            .parent<StackRouter>()!
                            .maybePop(),
                      ),
                      child: const Text('close host'),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.push(const PageRouteInfo('HostRoute')));
    await tester.pumpAndSettle();
    expect(find.text('close host'), findsOneWidget);
    expect(found, same(scopeController));

    await tester.tap(find.text('close host'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });

  // A page of a declarative router can't push onto that router, so a route of
  // the router above still has to reach the router above.
  testWidgets('A route of the parent pushed from a declarative page opens', (
    tester,
  ) async {
    late BuildContext pageContext;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HostRoute',
            builder: (_) => AutoRouter.declarative(
              routes: (_) => const [PageRouteInfo('ARoute')],
            ),
          ),
          children: [
            AutoRoute(
              path: '',
              page: PageInfo(
                'ARoute',
                builder: (_) => Builder(
                  builder: (context) {
                    pageContext = context;
                    return const Text('A');
                  },
                ),
              ),
            ),
          ],
        ),
        AutoRoute(
          path: '/other',
          page: PageInfo('OtherRoute', builder: (_) => const Text('Other')),
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(pageContext.router.push(const PageRouteInfo('OtherRoute')));
    await tester.pumpAndSettle();
    expect(find.text('Other'), findsOneWidget);
    expect(router.stack.map((page) => page.name), ['HostRoute', 'OtherRoute']);
  });
}
