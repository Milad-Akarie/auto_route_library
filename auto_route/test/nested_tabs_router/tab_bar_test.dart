import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/router/widgets/auto_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import 'router.dart';
import 'tabs_router_tests.dart';

void main() {
  runGeneralTests('TabBar');
  runGeneralTests('TabBar', useDefaultRoutes: true);
  late NestedTabsRouter router;
  setUp(() => router = NestedTabsRouter());

  Future<void> pumpRouter(WidgetTester tester) => pumpRouterConfigApp(
        tester,
        router.config(
          deepLinkBuilder: (_) => DeepLink.single(
            TabsHostRoute(tabsType: 'TabBar'),
          ),
        ),
      );

  testWidgets(
    'Scrolling through pages in AutoTabView should sync with active route',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1500);
      await pumpRouter(tester);
      final pageViewFinder = find.byType(AutoTabView);
      final scrollController = (tester.widget<AutoTabView>(pageViewFinder)).controller;
      expect(scrollController.index, 0);
      await tester.drag(pageViewFinder, const Offset(-200, 0.0));
      await tester.pumpAndSettle();
      expect(scrollController.index, 1);
      expectTopPage(router, Tab2Nested1Route.name);
      expect(router.urlState.path, '/tab2');
      await tester.drag(pageViewFinder, const Offset(-200, 0.0));
      await tester.pumpAndSettle();
      expect(scrollController.index, 2);
      expectTopPage(router, Tab3Nested1Route.name);
      expect(router.urlState.path, '/tab3');
      addTearDown(tester.view.resetPhysicalSize);
    },
  );
}
