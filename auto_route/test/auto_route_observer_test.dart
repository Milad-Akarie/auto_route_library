import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'router_test_utils.dart';

void main() {
  late ObserverRouter router;
  late AutoRouteObserver observer;

  setUp(() {
    observer = AutoRouteObserver();
    router = ObserverRouter();
  });

  Future<void> pumpRouter(WidgetTester tester) => pumpRouterApp(
        tester,
        router,
        observers: () => [observer],
      );

  testWidgets(
    'AutoRouteObserver should notify subscribers of push and pop events',
    (WidgetTester tester) async {
      await pumpRouter(tester);
      final state = tester.state<AutoRouteAwareTestPageState>(find.byType(AutoRouteAwareTestPage));

      router.push(const SecondRoute());
      await tester.pumpAndSettle();

      expect(state.didPushNextCalled, isTrue);
      expect(state.didPopNextCalled, isFalse);

      router.pop();
      await tester.pumpAndSettle();

      expect(state.didPopNextCalled, isTrue);
    },
  );

  testWidgets(
    'AutoRouteObserver should notify subscribers of tab events',
    (WidgetTester tester) async {
      await pumpRouter(tester);
      router.push(const TabsRoute());
      await tester.pumpAndSettle();

      final activeTabState = tester.state<AutoRouteAwareTestPageState>(
        find.byKey(const ValueKey('tab1')),
      );

      expect(activeTabState.didInitTabRouteCalled, isTrue);

      final tabsRouter = router.innerRouterOf<TabsRouter>(TabsRoute.name);
      expect(tabsRouter, isNotNull);

      // Switch to Tab 2
      tabsRouter?.setActiveIndex(1);
      await tester.pumpAndSettle();

      // Switch back to Tab 1 to trigger didChangeTabRoute for Tab 1
      tabsRouter?.setActiveIndex(0);
      await tester.pumpAndSettle();

      expect(activeTabState.didChangeTabRouteCalled, isTrue);
    },
  );

  testWidgets(
    'AutoRouteObserver should unsubscribe when widget is disposed',
    (WidgetTester tester) async {
      await pumpRouter(tester);
      expect(find.byType(AutoRouteAwareTestPage), findsOneWidget);

      router.replace(const SecondRoute());
      await tester.pumpAndSettle();

      expect(find.byType(AutoRouteAwareTestPage), findsNothing);
    },
  );
}

class AutoRouteAwareTestPage extends StatefulWidget {
  const AutoRouteAwareTestPage({super.key});

  @override
  State<AutoRouteAwareTestPage> createState() => AutoRouteAwareTestPageState();
}

class AutoRouteAwareTestPageState extends State<AutoRouteAwareTestPage> with AutoRouteAwareStateMixin {
  bool didPushNextCalled = false;
  bool didPopNextCalled = false;
  bool didPushCalled = false;
  bool didPopCalled = false;
  bool didInitTabRouteCalled = false;
  bool didChangeTabRouteCalled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(),
    );
  }

  @override
  void didPushNext() {
    didPushNextCalled = true;
  }

  @override
  void didPopNext() {
    didPopNextCalled = true;
  }

  @override
  void didPush() {
    didPushCalled = true;
  }

  @override
  void didPop() {
    didPopCalled = true;
  }

  @override
  void didInitTabRoute(TabPageRoute? previousRoute) {
    didInitTabRouteCalled = true;
  }

  @override
  void didChangeTabRoute(TabPageRoute previousRoute) {
    didChangeTabRouteCalled = true;
  }
}

// Router Configuration

class ObserverRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: FirstRoute.page, initial: true),
        AutoRoute(page: SecondRoute.page),
        AutoRoute(
          page: TabsRoute.page,
          children: [
            AutoRoute(page: Tab1Route.page),
            AutoRoute(page: Tab2Route.page),
          ],
        ),
      ];
}

class FirstRoute extends PageRouteInfo<void> {
  const FirstRoute({List<PageRouteInfo>? children}) : super(FirstRoute.name, initialChildren: children);

  static const String name = 'FirstRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (data) => const AutoRouteAwareTestPage(key: ValueKey('first')),
  );
}

class SecondRoute extends PageRouteInfo<void> {
  const SecondRoute({List<PageRouteInfo>? children}) : super(SecondRoute.name, initialChildren: children);

  static const String name = 'SecondRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (data) => const Scaffold(body: Text('Second Page')),
  );
}

class TabsRoute extends PageRouteInfo<void> {
  const TabsRoute({List<PageRouteInfo>? children}) : super(TabsRoute.name, initialChildren: children);

  static const String name = 'TabsRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (data) => AutoTabsRouter(
      routes: const [
        Tab1Route(),
        Tab2Route(),
      ],
    ),
  );
}

class Tab1Route extends PageRouteInfo<void> {
  const Tab1Route({List<PageRouteInfo>? children}) : super(Tab1Route.name, initialChildren: children);

  static const String name = 'Tab1Route';
  static PageInfo page = PageInfo(
    name,
    builder: (data) => const AutoRouteAwareTestPage(key: ValueKey('tab1')),
  );
}

class Tab2Route extends PageRouteInfo<void> {
  const Tab2Route({List<PageRouteInfo>? children}) : super(Tab2Route.name, initialChildren: children);

  static const String name = 'Tab2Route';
  static PageInfo page = PageInfo(
    name,
    builder: (data) => const Scaffold(body: Text('Tab 2')),
  );
}
