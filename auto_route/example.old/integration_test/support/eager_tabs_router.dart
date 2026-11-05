import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

// Tabs that build every page up front (lazyLoad: false), for
// eager_tabs_test.dart.

/// The tabs' route names, each page showing its name.
const eagerTabNames = ['NewsRoute', 'FeedRoute', 'ProfileRoute'];

/// The route name of the page holding the tabs.
const eagerTabsName = 'TabsRoute';

/// How many times each tab's page was created, by route name.
final eagerTabBuilds = <String, int>{};

/// The ways the tabs are shown.
enum EagerTabsKind {
  /// [AutoTabsRouter.tabBar].
  tabBar,

  /// [AutoTabsRouter.pageView].
  pageView,
}

/// A router whose first page shows [eagerTabNames] as [kind] tabs, with
/// lazyLoad: false.
RootStackRouter buildEagerTabsRouter(EagerTabsKind kind) {
  final routes = [for (final name in eagerTabNames) _Route(name)];
  return RootStackRouter.build(
    routes: [
      AutoRoute(
        page: PageInfo(
          eagerTabsName,
          builder: (_) => switch (kind) {
            .tabBar => AutoTabsRouter.tabBar(routes: routes, lazyLoad: false),
            .pageView => AutoTabsRouter.pageView(
              routes: routes,
              lazyLoad: false,
            ),
          },
        ),
        path: '/',
        children: [
          for (final name in eagerTabNames)
            AutoRoute(page: _page(name), path: name),
        ],
      ),
    ],
  );
}

PageInfo _page(String name) => .new(name, builder: (_) => _TabPage(name));

class _TabPage extends StatefulWidget {
  const _TabPage(this.name);

  final String name;

  @override
  State<_TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<_TabPage> {
  @override
  void initState() {
    super.initState();
    eagerTabBuilds.update(widget.name, (count) => count + 1, ifAbsent: () => 1);
  }

  @override
  Widget build(BuildContext context) => Center(child: Text(widget.name));
}

class _Route extends PageRouteInfo<void> {
  const _Route(super.name);
}
