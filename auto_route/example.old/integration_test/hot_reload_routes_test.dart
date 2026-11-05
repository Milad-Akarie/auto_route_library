import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// A route added to the router's list before a hot reload opens after it.
// flutter/flutter#105553
// Headless test: auto_route/test/hot_reload_routes_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('hot reload routes', () {
    // Steps: the app's routes are HomeRoute and a host with one child. Open
    // the host, add a top route and a child route to the list, hot reload,
    // then open each new route by its path.
    // Should: both open, as they do after a restart.
    testWidgets(
      'Routes added before a hot reload open by their paths (flutter/flutter#105553)',
      (tester) async {
        AutoRoute host(List<AutoRoute> children) => NamedRouteDef(
          name: 'HostRoute',
          path: '/host',
          builder: (_, _) => const AutoRouter(),
          children: children,
        );
        final child1 = NamedRouteDef(
          name: 'Child1Route',
          path: '',
          builder: (_, _) => const TextPage('Child1Route'),
        );
        final routes = [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => const TextPage('HomeRoute'),
          ),
          host([child1]),
        ];
        final router = RootStackRouter.build(routes: routes);
        await pumpRouterAppWithConfig(tester, router);
        unawaited(router.navigatePath('/host'));
        await pumpUntilFound(tester, find.text('Child1Route'));

        routes
          ..[1] = host([
            child1,
            NamedRouteDef(
              name: 'Child2Route',
              path: 'child2',
              builder: (_, _) => const TextPage('Child2Route'),
            ),
          ])
          ..add(
            NamedRouteDef(
              name: 'AddedRoute',
              path: '/added',
              builder: (_, _) => const TextPage('AddedRoute'),
            ),
          );
        unawaited(tester.binding.reassembleApplication());
        await tester.pumpAndSettle();

        unawaited(router.navigatePath('/host/child2'));
        await pumpUntilFound(tester, find.text('Child2Route'));
        expectTopPage(router, 'Child2Route');
        await expectBrowserUrl('/host/child2');

        unawaited(router.navigatePath('/added'));
        await pumpUntilFound(tester, find.text('AddedRoute'));
        expectCurrentPage(router, 'AddedRoute');
        await expectBrowserUrl('/added');
      },
    );
  });
}
