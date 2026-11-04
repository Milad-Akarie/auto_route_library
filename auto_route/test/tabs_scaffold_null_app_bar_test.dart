import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  late RootStackRouter router;

  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _TabsRoute.page,
          path: '/',
          initial: true,
          children: [
            AutoRoute(page: _ListRoute.page, path: 'list'),
            AutoRoute(page: _DetailRoute.page, path: 'detail', meta: const {'hideAppBar': true}),
          ],
        ),
      ],
    );
  });

  // Reproduces https://github.com/Milad-Akarie/auto_route_library/issues/856
  // Steps: an AutoTabsScaffold whose appBarBuilder returns null for a tab
  // whose route meta says hideAppBar, and an AppBar for the others. Show the
  // first tab, then the second.
  // Should: the first tab has an AppBar, the second has none, and nothing
  // throws.
  testWidgets('AutoTabsScaffold takes a null app bar from appBarBuilder', (tester) async {
    await pumpRouterApp(tester, router);
    expect(find.byType(AppBar), findsOneWidget);

    router.innerRouterOf<TabsRouter>(_TabsRoute.name)!.setActiveIndex(1);
    await tester.pumpAndSettle();

    expect(find.text(_DetailRoute.name), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _TabsRoute extends PageRouteInfo<void> {
  const _TabsRoute({List<PageRouteInfo>? children}) : super(name, initialChildren: children);

  static const String name = '_TabsRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => AutoTabsScaffold(
      animationDuration: .zero,
      appBarBuilder: (_, tabsRouter) =>
          tabsRouter.topMatch.meta['hideAppBar'] == true ? null : AppBar(title: const Text('Bar')),
    ),
  );
}

class _ListRoute extends PageRouteInfo<void> {
  const _ListRoute() : super(name);

  static const String name = '_ListRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}

class _DetailRoute extends PageRouteInfo<void> {
  const _DetailRoute() : super(name);

  static const String name = '_DetailRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}
