import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // Guards https://github.com/Milad-Akarie/auto_route_library/issues/1773
  // Steps: an AutoTabsScaffold with two routes counts the calls of its
  // bottomNavigationBuilder while the app opens, then on a tab change.
  // Reported: the builder runs twice when there is more than one route.
  // Should: it runs once to open the page, and once per tab change.
  testWidgets('AutoTabsScaffold builds its bottom navigation once when it opens', (WidgetTester tester) async {
    _bottomNavigationBuilds = 0;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _NavigationRoute.page,
          path: '/',
          initial: true,
          children: [
            AutoRoute(page: _UsersRoute.page, path: 'users'),
            AutoRoute(page: _PostsRoute.page, path: 'posts'),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    expect(find.text(_UsersRoute.name), findsOneWidget);
    expect(_bottomNavigationBuilds, 1);

    await tester.tap(find.text('Posts'));
    await tester.pumpAndSettle();
    expect(find.text(_PostsRoute.name), findsOneWidget);
    expect(_bottomNavigationBuilds, 2);
  });
}

var _bottomNavigationBuilds = 0;

class _NavigationRoute extends PageRouteInfo<void> {
  const _NavigationRoute() : super(name);

  static const String name = '_NavigationRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => AutoTabsScaffold(
      extendBodyBehindAppBar: true,
      routes: const [_UsersRoute(), _PostsRoute()],
      bottomNavigationBuilder: (context, tabsRouter) {
        _bottomNavigationBuilds++;
        return BottomNavigationBar(
          currentIndex: tabsRouter.activeIndex,
          onTap: tabsRouter.setActiveIndex,
          items: const [
            BottomNavigationBarItem(label: 'Users', icon: Icon(Icons.people)),
            BottomNavigationBarItem(label: 'Posts', icon: Icon(Icons.article)),
          ],
        );
      },
    ),
  );
}

class _UsersRoute extends PageRouteInfo<void> {
  const _UsersRoute() : super(name);

  static const String name = '_UsersRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}

class _PostsRoute extends PageRouteInfo<void> {
  const _PostsRoute() : super(name);

  static const String name = '_PostsRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}
