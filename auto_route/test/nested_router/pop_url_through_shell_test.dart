import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import '../named_page.dart';
import '../router_test_utils.dart';

// flutter/flutter#152301: popping back through pushed pages, and out of a
// child of a shell route, reported '/' as the location every time.
// The reporter's app: DashboardRoute at '/', then LoginRoute, PinRoute,
// HomeRoute and EndRoute, and EndRoute's nested router holds SubRoute at
// '/end/subroute'. Push LoginRoute, PinRoute, HomeRoute and EndRoute, push
// SubRoute in EndRoute's router, then pop five times: each pop shows the page
// before, and the url names it.
void main() {
  testWidgets('Each pop through pushed pages and out of a shell route reports the page under it', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(name: 'DashboardRoute', path: '/', builder: (_, _) => const NamedPage('DashboardRoute')),
        NamedRouteDef(name: 'LoginRoute', path: '/login', builder: (_, _) => const NamedPage('LoginRoute')),
        NamedRouteDef(name: 'PinRoute', path: '/pin', builder: (_, _) => const NamedPage('PinRoute')),
        NamedRouteDef(name: 'HomeRoute', path: '/home', builder: (_, _) => const NamedPage('HomeRoute')),
        NamedRouteDef(
          name: 'EndRoute',
          path: '/end',
          builder: (_, _) => const AutoRouter(),
          children: [
            NamedRouteDef(name: 'EndPageRoute', path: '', builder: (_, _) => const NamedPage('EndPageRoute')),
            NamedRouteDef(name: 'SubRoute', path: 'subroute', builder: (_, _) => const NamedPage('SubRoute')),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    for (final name in ['LoginRoute', 'PinRoute', 'HomeRoute', 'EndRoute']) {
      unawaited(router.push(NamedRoute(name)));
      await tester.pumpAndSettle();
    }
    final endRouter = router.innerRouterOf<StackRouter>('EndRoute')!;
    unawaited(endRouter.push(const NamedRoute('SubRoute')));
    await tester.pumpAndSettle();
    expect(router.currentUrl, '/end/subroute');

    for (final (name, url) in [
      ('EndPageRoute', '/end'),
      ('HomeRoute', '/home'),
      ('PinRoute', '/pin'),
      ('LoginRoute', '/login'),
      ('DashboardRoute', '/'),
    ]) {
      await router.maybePopTop();
      await tester.pumpAndSettle();
      expect(find.text(name), findsOneWidget);
      expect(router.currentUrl, url);
    }
  });
}
