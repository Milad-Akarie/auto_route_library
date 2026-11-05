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

  setUp(eagerTabBuilds.clear);

  for (final kind in EagerTabsKind.values) {
    testWidgets('${kind.name} with lazyLoad: false builds every tab before the first switch', (tester) async {
      final router = buildEagerTabsRouter(kind);
      await pumpRouterApp(tester, router);

      expect(eagerTabBuilds, {for (final name in eagerTabNames) name: 1});

      router.innerRouterOf<TabsRouter>(eagerTabsName)!.setActiveIndex(2);
      await tester.pumpAndSettle();

      expect(find.text(eagerTabNames[2]), findsOneWidget);
      expect(eagerTabBuilds, {for (final name in eagerTabNames) name: 1});
    });
  }
}
