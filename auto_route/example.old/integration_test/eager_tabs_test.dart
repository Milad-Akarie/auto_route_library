import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/eager_tabs_router.dart';

// AutoTabsRouter.tabBar and AutoTabsRouter.pageView build every tab up front
// with lazyLoad: false.
// https://github.com/Milad-Akarie/auto_route_library/issues/2013
// Headless test: auto_route/test/nested_tabs_router/tab_lazy_load_test.dart
//
// Steps: show the tabs, then switch to the last one.
// Should: every tab's page is built before the switch, once each, and the
// switch builds none again.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('eager tabs', () {
    setUp(eagerTabBuilds.clear);

    for (final kind in EagerTabsKind.values) {
      testWidgets(
        '${kind.name} with lazyLoad: false builds every tab before the first '
        'switch',
        (tester) async {
          final router = buildEagerTabsRouter(kind);
          await pumpRouterApp(tester, router);

          final earlier1 = eagerTabBuilds;

          router
              .innerRouterOf<TabsRouter>(kEagerTabsName)!
              .setActiveIndex(kEagerTabNames.length - 1);
          await tester.pumpAndSettle();

          expect(find.text(kEagerLastTabName), findsOneWidget);
          expect(
            [earlier1, eagerTabBuilds],
            [
              {for (final name in kEagerTabNames) name: 1},
              {for (final name in kEagerTabNames) name: 1},
            ],
          );
        },
      );
    }
  });
}
