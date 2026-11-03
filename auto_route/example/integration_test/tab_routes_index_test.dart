import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Removing the active tab from AutoTabsRouter.routes shows the first tab, with
// an AutoRouterObserver listening, instead of throwing a RangeError.
// https://github.com/Milad-Akarie/auto_route_library/issues/2308
// Headless test: auto_route/test/nested_tabs_router/tab_routes_index_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final kind in _TabsKind.values) {
    // Steps: tabs are [first, second] and an AutoRouterObserver listens. Open
    // the second tab, then tap 'Remove second tab' so the routes are [first].
    // Should: the first tab shows.
    testWidgets('${kind.name}: removing the active second tab shows the first tab', (tester) async {
      addTearDown(() => _secondRemovedNotifier.value = false);
      _tabsKind = kind;
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            page: _TabsHostRoute.page,
            path: '/',
            initial: true,
            children: [
              AutoRoute(page: _FirstTabRoute.page, path: 'first', initial: true),
              AutoRoute(page: _SecondTabRoute.page, path: 'second'),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(
        tester,
        router.config(
          deepLinkBuilder: (_) => DeepLink.defaultPath,
          navigatorObservers: () => [AutoRouterObserver()],
        ),
      );

      await tester.tap(find.text('Go to second tab'));
      await tester.pumpAndSettle();
      expect(find.text(_SecondTabRoute.name), findsOneWidget);

      await tester.tap(find.text('Remove second tab'));
      await tester.pumpAndSettle();
      expect(find.text(_FirstTabRoute.name), findsOneWidget);
      expect(find.text(_SecondTabRoute.name), findsNothing);
    });
  }
}

enum _TabsKind { indexedStack, pageView, tabBar, builder }

var _tabsKind = _TabsKind.indexedStack;

final _secondRemovedNotifier = ValueNotifier<bool>(false);

class _TabsHostRoute extends PageRouteInfo<void> {
  const _TabsHostRoute() : super(name);

  static const String name = '_TabsHostRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => ValueListenableBuilder<bool>(
      valueListenable: _secondRemovedNotifier,
      builder: (context, secondRemoved, _) {
        final routes = [const _FirstTabRoute(), if (!secondRemoved) const _SecondTabRoute()];
        return switch (_tabsKind) {
          _TabsKind.indexedStack => AutoTabsRouter(routes: routes),
          _TabsKind.pageView => AutoTabsRouter.pageView(routes: routes),
          _TabsKind.tabBar => AutoTabsRouter.tabBar(routes: routes),
          _TabsKind.builder => AutoTabsRouter.builder(
            routes: routes,
            builder: (context, children, tabsRouter) => IndexedStack(index: tabsRouter.activeIndex, children: children),
          ),
        };
      },
    ),
  );
}

class _FirstTabRoute extends PageRouteInfo<void> {
  const _FirstTabRoute() : super(name);

  static const String name = '_FirstTabRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (context) => Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Text(name),
            Builder(
              builder: (context) => TextButton(
                onPressed: () => context.tabsRouter.setActiveIndex(1),
                child: const Text('Go to second tab'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SecondTabRoute extends PageRouteInfo<void> {
  const _SecondTabRoute() : super(name);

  static const String name = '_SecondTabRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Text(name),
            TextButton(onPressed: () => _secondRemovedNotifier.value = true, child: const Text('Remove second tab')),
          ],
        ),
      ),
    ),
  );
}
