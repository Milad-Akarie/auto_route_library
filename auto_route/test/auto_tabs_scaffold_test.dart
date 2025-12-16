import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'main_router.dart';
import 'router_test_utils.dart';

void main() {
  late TabsScaffoldRouter router;

  setUp(() {
    router = TabsScaffoldRouter();
  });

  testWidgets(
    'AutoTabsScaffold should show first tab by default',
    (WidgetTester tester) async {
      await pumpRouterApp(tester, router);
      expect(find.text(FirstRoute.name), findsOneWidget);
    },
  );

  testWidgets(
    'AutoTabsScaffold should render bottom navigation',
    (WidgetTester tester) async {
      await pumpRouterApp(tester, router);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    },
  );

  testWidgets(
    'AutoTabsScaffold should switch tabs via bottom navigation',
    (WidgetTester tester) async {
      await pumpRouterApp(tester, router);
      expect(find.text(FirstRoute.name), findsOneWidget);
      // can I get a screenshot here
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tab2Key')));
      await tester.pumpAndSettle();
      expectTopPage(router, SecondRoute.name);
    },
  );

  testWidgets(
    'AutoTabsScaffold should render app bar',
    (WidgetTester tester) async {
      await pumpRouterApp(tester, router);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('My App Bar'), findsOneWidget);
    },
  );

  testWidgets(
    'AutoTabsScaffold should render bottom navigation',
    (WidgetTester tester) async {
      await pumpRouterApp(tester, router);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    },
  );

  testWidgets(
    'AutoTabsScaffold should use default routes if no children are provided',
    (WidgetTester tester) async {
      final router = RootStackRouter.build(routes: [
        AutoRoute(page: TabsScaffoldDefaultRoute.page, initial: true, children: [
          AutoRoute(page: FirstRoute.page),
          AutoRoute(page: SecondRoute.page),
        ]),
      ]);
      await pumpRouterApp(tester, router);
      final tabsRouter = router.innerRouterOf(TabsScaffoldDefaultRoute.name);
      expect(tabsRouter, isA<TabsRouter>());
      expect(tabsRouter!.pageCount, 2);
      expect(tabsRouter.stackData.map((e) => e.name), [FirstRoute.name, SecondRoute.name]);
      expect(find.text(FirstRoute.name), findsOneWidget);
    },
  );

  // should throw if building default routes when one has required arguments
  testWidgets(
    'AutoTabsScaffold should throw (FlutterError) if building default routes when one has required arguments',
    (WidgetTester tester) async {
      final router = RootStackRouter.build(routes: [
        AutoRoute(page: TabsScaffoldDefaultRoute.page, initial: true, children: [
          AutoRoute(page: FirstRoute.page),
          AutoRoute(page: TabPageWithRequiredArgument.page),
        ]),
      ]);
      await pumpRouterApp(tester, router);
      expect(tester.takeException(), isA<FlutterError>());
    },
  );
}

// Router Configuration
class TabsScaffoldRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: TabsScaffoldRoute.page,
          initial: true,
          children: [
            AutoRoute(page: FirstRoute.page),
            AutoRoute(page: SecondRoute.page),
          ],
        ),
      ];
}

class TabsScaffoldRoute extends PageRouteInfo<void> {
  const TabsScaffoldRoute({List<PageRouteInfo>? children}) : super(TabsScaffoldRoute.name, initialChildren: children);

  static const String name = 'TabsScaffoldRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (data) => AutoTabsScaffold(
      routes: const [
        FirstRoute(),
        SecondRoute(),
      ],
      animationDuration: Duration.zero,
      appBarBuilder: (_, __) => AppBar(title: const Text('My App Bar')),
      bottomNavigationBuilder: (_, tabsRouter) {
        return BottomNavigationBar(
          currentIndex: tabsRouter.activeIndex,
          onTap: tabsRouter.setActiveIndex,
          items: const [
            BottomNavigationBarItem(label: 'Tab 1 Label', icon: Icon(Icons.one_k)),
            BottomNavigationBarItem(label: 'Tab 2 Label', icon: Icon(Icons.two_k), key: ValueKey('tab2Key')),
          ],
        );
      },
    ),
  );
}

class TabsScaffoldDefaultRoute extends PageRouteInfo<void> {
  const TabsScaffoldDefaultRoute() : super(TabsScaffoldDefaultRoute.name);

  static const String name = 'TabsScaffoldDefaultRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (data) => AutoTabsScaffold(),
  );
}

class TabPageWithRequiredArgument extends PageRouteInfo<void> {
  const TabPageWithRequiredArgument({required this.argument}) : super(TabPageWithRequiredArgument.name);

  static const String name = 'TabPageWithRequiredArgument';
  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<String>();
      return Scaffold(body: Text(args));
    },
  );

  final String argument;
}
