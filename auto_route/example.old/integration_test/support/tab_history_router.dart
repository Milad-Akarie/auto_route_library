import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

// A tabs screen whose back goes through the tabs visited
// (AutoTabsRouter.backThroughHistory), for tab_history_back_test.dart.

/// The tabs' route names, each page showing its name.
const tabHistoryTabNames = ['NewsRoute', 'FeedRoute', 'RankingRoute', 'ProfileRoute'];

/// The route name of the page under the tabs, when there is one.
const tabHistoryFirstPageName = 'FirstRoute';

/// The route name of the page holding the tabs.
const tabHistoryTabsName = 'TabsRoute';

/// A router whose tabs page is the first page, or, with [overFirstPage],
/// sits at `/tabs` over a first page at `/`.
RootStackRouter buildTabHistoryRouter({bool overFirstPage = false}) {
  return RootStackRouter.build(
    routes: [
      if (overFirstPage) AutoRoute(page: _page(tabHistoryFirstPageName), path: '/'),
      AutoRoute(
        page: _tabsPage,
        path: overFirstPage ? '/tabs' : '/',
        children: [for (final name in tabHistoryTabNames) AutoRoute(page: _page(name), path: name)],
      ),
    ],
  );
}

/// The route of the tabs page, to push over the first page.
const tabHistoryTabsRoute = _Route(tabHistoryTabsName);

final _tabsPage = PageInfo(
  tabHistoryTabsName,
  builder: (_) => AutoTabsRouter(
    backThroughHistory: true,
    routes: [for (final name in tabHistoryTabNames) _Route(name)],
  ),
);

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(body: Center(child: Text(name))),
);

class _Route extends PageRouteInfo<void> {
  const _Route(super.name);
}
