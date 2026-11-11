import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1962
// Setup, as in the report: an AutoTabsRouter.pageView with two tabs, Animals
// and Colors. The Colors page is only an AutoRouter; its children are the list
// (path '') and the detail (path 'detail/:id', usesPathAsKey) as siblings.
// Steps: start the app on /colors/detail/5, before the Colors list ever
// loaded; second, start on the Animals tab and navigate to
// /colors/detail/5.
// Reported: the Colors tab shows its list, the sibling with path '', and
// not the detail; navigating again then works.
// Should: the Colors tab shows the detail of color 5 at once.
void main() {
  late RootStackRouter router;

  setUp(() {
    router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          initial: true,
          builder: (_, _) => const AutoTabsRouter.pageView(
            routes: [NamedRoute('AnimalsRoute'), NamedRoute('ColorsRoute')],
          ),
          children: [
            NamedRouteDef(
              name: 'AnimalsRoute',
              path: 'animals',
              initial: true,
              builder: (_, _) => const Text('Animals'),
            ),
            NamedRouteDef(
              name: 'ColorsRoute',
              path: 'colors',
              builder: (_, _) => const AutoRouter(),
              children: [
                NamedRouteDef(
                  name: 'ColorsListRoute',
                  path: '',
                  builder: (_, _) => const Text('Colors list'),
                ),
                NamedRouteDef(
                  name: 'ColorsDetailsRoute',
                  path: 'detail/:id',
                  usesPathAsKey: true,
                  builder: (_, data) =>
                      Text('Color ${data.inheritedPathParams.getString('id')}'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  });

  testWidgets('A link to a sibling detail on a tab not shown yet opens it', (
    tester,
  ) async {
    await pumpRouterConfigApp(
      tester,
      router.config(
        deepLinkBuilder: (_) => const DeepLink.path('/colors/detail/5'),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Color 5'), findsOneWidget);
    expect(find.text('Colors list'), findsNothing);
    expect(router.currentPath, '/colors/detail/5');
  });

  testWidgets(
    'Navigating to a sibling detail on a tab not shown yet opens it',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      expect(find.text('Animals'), findsOneWidget);

      unawaited(router.navigatePath('/colors/detail/5'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Color 5'), findsOneWidget);
      expect(find.text('Colors list'), findsNothing);
      expect(router.currentPath, '/colors/detail/5');
    },
  );
}
