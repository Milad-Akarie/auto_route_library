import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// innerRouterOf finds a tab's nested router after AutoTabsRouter's routes change.
// https://github.com/Milad-Akarie/auto_route_library/issues/2189
// Headless test: auto_route/test/nested_tabs_router/tab_inner_router_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final kind in _TabsKind.values) {
    // Steps: tabs are [nestedHost, if (extra) extra, second]; nestedHost
    // holds a nested router. Tap 'To nested second', 'Toggle extra', then
    // 'Re-tap active tab', which pops the active tab's nested router found
    // with innerRouterOf to its first page.
    // Should: the nested first page shows.
    testWidgets('${kind.name}: re-tapping the active tab after the routes change pops its nested router', (
      tester,
    ) async {
      addTearDown(() => _extraNotifier.value = false);
      _tabsKind = kind;
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            page: _HostRoute.page,
            path: '/',
            initial: true,
            children: [
              AutoRoute(
                page: _NestedHostRoute.page,
                path: 'nested',
                initial: true,
                children: [
                  AutoRoute(page: _NestedFirstRoute.page, path: '', initial: true),
                  AutoRoute(page: _NestedSecondRoute.page, path: 'second'),
                ],
              ),
              AutoRoute(page: _ExtraRoute.page, path: 'extra'),
              AutoRoute(page: _SecondRoute.page, path: 'second'),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config(deepLinkBuilder: (_) => DeepLink.defaultPath));

      await tester.tap(find.text('To nested second'));
      await tester.pumpAndSettle();
      expect(find.text(_NestedSecondRoute.name), findsOneWidget);
      await tester.tap(find.text('Toggle extra'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Re-tap active tab'));
      await tester.pumpAndSettle();
      expect(find.text(_NestedFirstRoute.name), findsOneWidget);
      expect(find.text(_NestedSecondRoute.name), findsNothing);
    });
  }
}

enum _TabsKind { indexedStack, pageView, tabBar, builder }

_TabsKind _tabsKind = .indexedStack;

final _extraNotifier = ValueNotifier<bool>(false);

class _HostRoute extends PageRouteInfo<void> {
  const _HostRoute() : super(name);

  static const String name = '_HostRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => ValueListenableBuilder<bool>(
      valueListenable: _extraNotifier,
      builder: (context, extra, _) {
        final routes = [const _NestedHostRoute(), if (extra) const _ExtraRoute(), const _SecondRoute()];
        return switch (_tabsKind) {
          .indexedStack => AutoTabsRouter(routes: routes),
          .pageView => AutoTabsRouter.pageView(routes: routes),
          .tabBar => AutoTabsRouter.tabBar(routes: routes),
          .builder => AutoTabsRouter.builder(
            routes: routes,
            builder: (context, children, tabsRouter) => IndexedStack(
              index: tabsRouter.activeIndex,
              children: children,
            ),
          ),
        };
      },
    ),
  );
}

class _NestedHostRoute extends PageRouteInfo<void> {
  const _NestedHostRoute() : super(name);

  static const String name = '_NestedHostRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const AutoRouter());
}

class _NestedFirstRoute extends PageRouteInfo<void> {
  const _NestedFirstRoute() : super(name);

  static const String name = '_NestedFirstRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (context) => Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Text(name),
            Builder(
              builder: (context) => TextButton(
                onPressed: () => context.router.push(const _NestedSecondRoute()),
                child: const Text('To nested second'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NestedSecondRoute extends PageRouteInfo<void> {
  const _NestedSecondRoute() : super(name);

  static const String name = '_NestedSecondRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (context) => Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Text(name),
            TextButton(
              onPressed: () => _extraNotifier.value = !_extraNotifier.value,
              child: const Text('Toggle extra'),
            ),
            Builder(
              builder: (context) => TextButton(
                // What re-tapping the active tab does in the report.
                onPressed: () {
                  final tabsRouter = context.tabsRouter;
                  final innerRouter = tabsRouter.innerRouterOf<StackRouter>(tabsRouter.current.name);
                  if (innerRouter?.canPop() ?? false) innerRouter!.popUntilRoot();
                },
                child: const Text('Re-tap active tab'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ExtraRoute extends PageRouteInfo<void> {
  const _ExtraRoute() : super(name);

  static const String name = '_ExtraRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
}

class _SecondRoute extends PageRouteInfo<void> {
  const _SecondRoute() : super(name);

  static const String name = '_SecondRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
}
