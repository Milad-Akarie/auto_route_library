import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import '../named_page.dart';
import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1363
  // replace with the route already on top, given other nested children,
  // changed the url but left the nested pages as they were.
  // Steps: open '/dashboard/activities/done', then replace with
  // DashboardRoute(children: [ActivitiesRoute(children: [PendingRoute()])]).
  // Should: the nested router shows Pending, and the url follows.
  testWidgets('replace with the same route and other nested children opens those children', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef.shell(
          name: 'DashboardRoute',
          path: '/dashboard',
          children: [
            NamedRouteDef.shell(
              name: 'ActivitiesRoute',
              path: 'activities',
              children: [
                NamedRouteDef(name: 'PendingRoute', path: '', builder: (_, _) => const NamedPage('PendingRoute')),
                NamedRouteDef(name: 'DoneRoute', path: 'done', builder: (_, _) => const NamedPage('DoneRoute')),
              ],
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router, initialLink: '/dashboard/activities/done');
    expect(find.text('DoneRoute'), findsOneWidget);

    router.markUrlStateForReplace();
    unawaited(
      router.replace(
        const NamedRoute(
          'DashboardRoute',
          children: [
            NamedRoute('ActivitiesRoute', children: [NamedRoute('PendingRoute')]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('PendingRoute'), findsOneWidget);
    expect(find.text('DoneRoute'), findsNothing);
    expect(router.urlState.url, '/dashboard/activities');
    expect(router.stack.map((p) => p.name), ['DashboardRoute']);
  });
}
