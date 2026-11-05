import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:material_ui/material_ui.dart';

import 'main_router.dart';
import 'router_test_utils.dart';

void main() {
  late _TabsScaffoldRouter router;

  setUp(() {
    router = _TabsScaffoldRouter();
  });

  testWidgets('AutoTabsScaffold should show first tab by default', (
    tester,
  ) async {
    await pumpRouterApp(tester, router);
    expect(find.text(FirstRoute.name), findsOneWidget);
  });

  testWidgets('AutoTabsScaffold should render bottom navigation', (
    tester,
  ) async {
    await pumpRouterApp(tester, router);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('AutoTabsScaffold should switch tabs via bottom navigation', (
    tester,
  ) async {
    await pumpRouterApp(tester, router);
    expect(find.text(FirstRoute.name), findsOneWidget);
    // can I get a screenshot here
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab2Key')));
    await tester.pumpAndSettle();
    expectTopPage(router, SecondRoute.name);
  });

  testWidgets('AutoTabsScaffold should render app bar', (tester) async {
    await pumpRouterApp(tester, router);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('My App Bar'), findsOneWidget);
  });

  testWidgets(
    'AutoTabsScaffold should use default routes if no children are provided',
    (tester) async {
      final localRouter = RootStackRouter.build(
        routes: [
          AutoRoute(
            page: _TabsScaffoldDefaultRoute.page,
            initial: true,
            children: [
              AutoRoute(page: FirstRoute.page),
              AutoRoute(page: SecondRoute.page),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, localRouter);
      final tabsRouter = localRouter.innerRouterOf(
        _TabsScaffoldDefaultRoute.name,
      );
      expect(tabsRouter, isA<TabsRouter>());
      expect(tabsRouter!.pageCount, 2);
      expect(tabsRouter.stackData.map((e) => e.name), [
        FirstRoute.name,
        SecondRoute.name,
      ]);
      expect(find.text(FirstRoute.name), findsOneWidget);
    },
  );

  // should throw if building default routes when one has required arguments
  testWidgets(
    'AutoTabsScaffold should throw (FlutterError) if building default routes when one has required arguments',
    (tester) async {
      final localRouter = RootStackRouter.build(
        routes: [
          AutoRoute(
            page: _TabsScaffoldDefaultRoute.page,
            initial: true,
            children: [
              AutoRoute(page: FirstRoute.page),
              AutoRoute(page: _TabPageWithRequiredArgument.page),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, localRouter);
      expect(tester.takeException(), isA<FlutterError>());
    },
    // The tabs router throws while Flutter mounts it, so Flutter never
    // unmounts it and never disposes its state, ticker and animation.
    experimentalLeakTesting: LeakTesting.settings.withIgnoredAll(),
  );
}

// Router Configuration
class _TabsScaffoldRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: _TabsScaffoldRoute.page,
      initial: true,
      children: [
        AutoRoute(page: FirstRoute.page),
        AutoRoute(page: SecondRoute.page),
      ],
    ),
  ];
}

abstract final class _TabsScaffoldRoute {
  static const String name = 'TabsScaffoldRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (data) => AutoTabsScaffold(
      routes: const [FirstRoute(), SecondRoute()],
      animationDuration: .zero,
      appBarBuilder: (_, _) => AppBar(title: const Text('My App Bar')),
      bottomNavigationBuilder: (_, tabsRouter) {
        return BottomNavigationBar(
          currentIndex: tabsRouter.activeIndex,
          onTap: tabsRouter.setActiveIndex,
          items: const [
            BottomNavigationBarItem(
              label: 'Tab 1 Label',
              icon: Icon(Icons.one_k),
            ),
            BottomNavigationBarItem(
              label: 'Tab 2 Label',
              icon: Icon(Icons.two_k),
              key: ValueKey('tab2Key'),
            ),
          ],
        );
      },
    ),
  );
}

abstract final class _TabsScaffoldDefaultRoute {
  static const String name = 'TabsScaffoldDefaultRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (data) => const AutoTabsScaffold(),
  );
}

// A test route whose page reads a required argument.
abstract final class _TabPageWithRequiredArgument {
  static const String name = 'TabPageWithRequiredArgument';
  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<String>();
      return Scaffold(body: Text(args));
    },
  );
}
