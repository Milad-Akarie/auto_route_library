import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

// A tabs screen whose back goes through the tabs visited
// (AutoTabsRouter.backThroughHistory), for tab_history_back_test.dart.

/// The tabs' route names, each page showing its name.
const kTabHistoryTabNames = [
  'NewsRoute',
  'FeedRoute',
  'RankingRoute',
  'ProfileRoute',
];

/// The route name of the page under the tabs, when there is one.
const kTabHistoryFirstPageName = 'FirstRoute';

/// The route name of the page holding the tabs.
const kTabHistoryTabsName = 'TabsRoute';

/// A router whose tabs page is the first page, or, with [isOverFirstPage],
/// sits at `/tabs` over a first page at `/`.
RootStackRouter buildTabHistoryRouter({bool isOverFirstPage = false}) {
  return RootStackRouter.build(
    routes: [
      if (isOverFirstPage)
        AutoRoute(page: _page(kTabHistoryFirstPageName), path: '/'),
      AutoRoute(
        page: _tabsPage,
        path: isOverFirstPage ? '/tabs' : '/',
        children: [
          for (final name in kTabHistoryTabNames)
            AutoRoute(page: _page(name), path: name),
        ],
      ),
    ],
  );
}

/// The route of the tabs page, to push over the first page.
const kTabHistoryTabsRoute = _Route(kTabHistoryTabsName);

final _tabsPage = PageInfo(
  kTabHistoryTabsName,
  builder: (_) => AutoTabsRouter(
    backThroughHistory: true,
    routes: [for (final name in kTabHistoryTabNames) _Route(name)],
  ),
);

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(body: Center(child: Text(name))),
);

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
