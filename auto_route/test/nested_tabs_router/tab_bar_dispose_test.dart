import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  tearDownAll(_routesNotifier.dispose);
  tearDownAll(_showTabsNotifier.dispose);
  // Reproduces https://github.com/Milad-Akarie/auto_route_library/issues/1765
  // Steps: an AutoTabsRouter.tabBar has routes [first, second, third]. Start
  // moving to the third tab, change the routes while the tab bar animates,
  // then remove the AutoTabsRouter before the animation ends.
  // Happens: the TabController replaced by the routes change is never
  // disposed. Its animation keeps running after the AutoTabsRouter is gone,
  // and its listener then calls setActiveIndex on the disposed router: the
  // reported "Null check operator used on a null value" in
  // _AutoTabsRouterTabBarState._updateTabController. In debug builds Flutter
  // reports it first as a Ticker still active when the state is disposed.
  // Should: nothing is thrown.
  testWidgets('a tab-bar AutoTabsRouter removed while its tab bar animates after a routes change throws nothing', (
    tester,
  ) async {
    addTearDown(() {
      _routesNotifier.value = _kInitialRoutes;
      _showTabsNotifier.value = true;
    });
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _TabsHostRoute.page,
          path: '/',
          initial: true,
          children: [
            AutoRoute(page: _FirstTabRoute.page, path: 'first'),
            AutoRoute(page: _SecondTabRoute.page, path: 'second'),
            AutoRoute(page: _ThirdTabRoute.page, path: 'third'),
            AutoRoute(page: _FourthTabRoute.page, path: 'fourth'),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    router.innerRouterOf<TabsRouter>(_TabsHostRoute.name)!.setActiveIndex(2);
    await tester.pump(const Duration(milliseconds: 50));

    _routesNotifier.value = [..._kInitialRoutes, const _FourthTabRoute()];
    await tester.pump(const Duration(milliseconds: 20));

    _showTabsNotifier.value = false;
    await tester.pumpAndSettle();
    expect(find.text('No tabs'), findsOneWidget);
  });

  // The same without a routes change: the TabController in use is disposed
  // with the AutoTabsRouter, so its animation stops with it.
  testWidgets('a tab-bar AutoTabsRouter removed while its tab bar animates throws nothing', (tester) async {
    addTearDown(() => _showTabsNotifier.value = true);
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _TabsHostRoute.page,
          path: '/',
          initial: true,
          children: [
            AutoRoute(page: _FirstTabRoute.page, path: 'first'),
            AutoRoute(page: _SecondTabRoute.page, path: 'second'),
            AutoRoute(page: _ThirdTabRoute.page, path: 'third'),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    router.innerRouterOf<TabsRouter>(_TabsHostRoute.name)!.setActiveIndex(2);
    await tester.pump(const Duration(milliseconds: 50));

    _showTabsNotifier.value = false;
    await tester.pumpAndSettle();
    expect(find.text('No tabs'), findsOneWidget);
  });
}

const _kInitialRoutes = <PageRouteInfo>[_FirstTabRoute(), _SecondTabRoute(), _ThirdTabRoute()];

final _routesNotifier = ValueNotifier<List<PageRouteInfo>>(_kInitialRoutes);

final ValueNotifier<bool> _showTabsNotifier = ValueNotifier(true);

class _TabsHostRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_TabsHostRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => ListenableBuilder(
      listenable: Listenable.merge([_routesNotifier, _showTabsNotifier]),
      builder: (context, _) {
        if (!_showTabsNotifier.value) return const Text('No tabs');
        return AutoTabsRouter.tabBar(routes: _routesNotifier.value);
      },
    ),
  );
}

class _FirstTabRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_FirstTabRoute';
  static final PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}

class _SecondTabRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_SecondTabRoute';
  static final PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}

class _ThirdTabRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_ThirdTabRoute';
  static final PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}

class _FourthTabRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_FourthTabRoute';
  static final PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}
