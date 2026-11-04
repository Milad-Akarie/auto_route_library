import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/618
  // Setup, as reported: an AutoTabsScaffold whose appBarBuilder returns an app
  // bar of its own, 120 logical pixels high.
  // Reported: the scaffold wrapped it in a PreferredSize of kToolbarHeight, so
  // the height could not be chosen.
  // Should: the scaffold's app bar has the height the builder's widget asks for.
  testWidgets('the app bar of AutoTabsScaffold has the height its builder asks for', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _HostRoute.page,
          path: '/',
          children: [AutoRoute(page: _TabRoute.page, path: 'tab')],
        ),
      ],
    );
    await pumpRouterApp(tester, router);

    final bar = find.byKey(const ValueKey('bar'));
    expect(bar, findsOneWidget);
    expect(tester.getSize(bar).height, 120);
    expect(tester.getTopLeft(find.text('Tab')).dy, greaterThanOrEqualTo(120));
  });
}

class _HostRoute extends PageRouteInfo<void> {
  const _HostRoute({List<PageRouteInfo>? children}) : super(name, initialChildren: children);

  static const String name = 'HostRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => AutoTabsScaffold(
      routes: const [_TabRoute()],
      appBarBuilder: (_, _) => const PreferredSize(
        preferredSize: Size.fromHeight(120),
        child: SizedBox(
          key: ValueKey('bar'),
          height: 120,
          child: ColoredBox(color: Colors.blue),
        ),
      ),
    ),
  );
}

class _TabRoute extends PageRouteInfo<void> {
  const _TabRoute() : super(name);

  static const String name = 'TabRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Text('Tab'));
}
