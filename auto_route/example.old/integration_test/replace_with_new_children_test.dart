import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// replace with the route already on top, given other nested children, opens
// those children.
// https://github.com/Milad-Akarie/auto_route_library/issues/1363
// Headless test:
// auto_route/test/nested_router/replace_with_new_children_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: open '/dashboard/activities/done', then replace with
  // DashboardRoute(children: [ActivitiesRoute(children: [PendingRoute()])]).
  // Should: the nested router shows Pending, and the url follows.
  testWidgets(
    'replace with the same route and other nested children opens those '
    'children',
    (tester) async {
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
                  NamedRouteDef(
                    name: 'PendingRoute',
                    path: '',
                    builder: (_, _) => const TextPage('Pending'),
                  ),
                  NamedRouteDef(
                    name: 'DoneRoute',
                    path: 'done',
                    builder: (_, _) => const TextPage('Done'),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      await pumpRouterApp(
        tester,
        router,
        initialLink: '/dashboard/activities/done',
      );
      expect(find.text('Done'), findsOneWidget);

      router.markUrlStateForReplace();
      unawaited(
        router.replace(
          const NamedRoute(
            'DashboardRoute',
            children: [
              NamedRoute(
                'ActivitiesRoute',
                children: [NamedRoute('PendingRoute')],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Done'), findsNothing);
      expect(router.urlState.url, '/dashboard/activities');
      await expectBrowserUrl('/dashboard/activities');
    },
  );
}
