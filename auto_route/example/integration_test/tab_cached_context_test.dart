import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A tab page switches tabs through the AutoTabsRouter builder's context it kept.
// https://github.com/Milad-Akarie/auto_route_library/issues/2252
// Headless test: auto_route/test/nested_tabs_router/tab_cached_context_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final kind in _TabsKind.values) {
    // Steps: the AutoTabsRouter's builder keeps its context. Tap 'Open the
    // second tab', then 'Back to the first tab'; both call
    // AutoTabsRouter.of(keptContext).setActiveIndex.
    // Should: each tab shows.
    testWidgets('${kind.name}: setActiveIndex through the kept builder context opens the tab', (tester) async {
      _tabsKind = kind;
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            page: _TabsHostRoute.page,
            path: '/',
            initial: true,
            children: [
              AutoRoute(page: _FirstTabRoute.page, path: 'first'),
              AutoRoute(page: _SecondTabRoute.page, path: 'second'),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config(deepLinkBuilder: (_) => DeepLink.defaultPath));

      await tester.tap(find.text('Open the second tab'));
      await tester.pumpAndSettle();
      expect(find.text(_SecondTabRoute.name), findsOneWidget);
      await tester.tap(find.text('Back to the first tab'));
      await tester.pumpAndSettle();
      expect(find.text(_FirstTabRoute.name), findsOneWidget);
    });
  }
}

enum _TabsKind { indexedStack, pageView, tabBar, builder }

_TabsKind _tabsKind = .indexedStack;

// The context of the AutoTabsRouter's builder, kept for the tab pages.
late BuildContext _keptContext;

class _TabsHostRoute extends PageRouteInfo<void> {
  const _TabsHostRoute() : super(name);

  static const String name = '_TabsHostRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) {
      const routes = [_FirstTabRoute(), _SecondTabRoute()];
      return switch (_tabsKind) {
        .indexedStack => AutoTabsRouter(
          routes: routes,
          builder: (context, child) {
            _keptContext = context;
            return child;
          },
        ),
        .pageView => AutoTabsRouter.pageView(
          routes: routes,
          builder: (context, child, _) {
            _keptContext = context;
            return child;
          },
        ),
        .tabBar => AutoTabsRouter.tabBar(
          routes: routes,
          builder: (context, child, _) {
            _keptContext = context;
            return child;
          },
        ),
        .builder => AutoTabsRouter.builder(
          routes: routes,
          builder: (context, children, tabsRouter) {
            _keptContext = context;
            return IndexedStack(index: tabsRouter.activeIndex, children: children);
          },
        ),
      };
    },
  );
}

class _FirstTabRoute extends PageRouteInfo<void> {
  const _FirstTabRoute() : super(name);

  static const String name = '_FirstTabRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Text(name),
            TextButton(
              onPressed: () => AutoTabsRouter.of(_keptContext).setActiveIndex(1),
              child: const Text('Open the second tab'),
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
            TextButton(
              onPressed: () => AutoTabsRouter.of(_keptContext).setActiveIndex(0),
              child: const Text('Back to the first tab'),
            ),
          ],
        ),
      ),
    ),
  );
}
