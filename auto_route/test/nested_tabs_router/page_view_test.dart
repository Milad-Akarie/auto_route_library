import 'package:auto_route/src/router/controller/routing_controller.dart';
import 'package:auto_route/src/router/widgets/auto_page_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import 'router.dart';
import 'tabs_router_tests.dart';

void main() {
  runGeneralTests('PageView');
  runGeneralTests('PageView', useDefaultRoutes: true);
  late NestedTabsRouter router;
  setUp(() => router = NestedTabsRouter());

  Future<void> pumpRouter(WidgetTester tester) => pumpRouterConfigApp(
        tester,
        router.config(
          deepLinkBuilder: (_) => DeepLink.single(
            TabsHostRoute(tabsType: 'PageView'),
          ),
        ),
      );

  testWidgets(
    'Scrolling through pages in AutoPageView should sync with active route',
    (WidgetTester tester) async {
      await pumpRouter(tester);
      final pageViewFinder = find.byType(AutoPageView);
      final scrollController = (tester.widget<AutoPageView>(pageViewFinder)).controller;
      expect(scrollController.page, 0);
      final dragOffset = scrollController.position.maxScrollExtent * .35;
      await tester.drag(pageViewFinder, Offset(-dragOffset, 0.0));
      await tester.pumpAndSettle();
      expect(scrollController.page, 1);
      expectTopPage(router, Tab2Nested1Route.name);
      expect(router.urlState.url, '/tab2');
      await tester.drag(pageViewFinder, Offset(-dragOffset, 0.0));
      await tester.pumpAndSettle();
      expect(scrollController.page, 2);
      expectTopPage(router, Tab3Nested1Route.name);
      expect(router.urlState.url, '/tab3');
    },
  );
}
