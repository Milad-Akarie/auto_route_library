import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// Feature request https://github.com/Milad-Akarie/auto_route_library/issues/2013
// (also asked of go_router: flutter/flutter#127804, #162055): build every tab
// of AutoTabsRouter.tabBar and AutoTabsRouter.pageView up front, as the
// default constructor does with lazyLoad: false.
// Steps: show the tabs with lazyLoad: false, before switching tab.
// Before: only the active tab's page is built; the others wait for their
// first visit, and those constructors had no lazyLoad.
// Now: every tab's page is built at once, and each is built only once.
// Observers hear of every tab as initialized, as with the default
// constructor, and switching tabs is then a change, not a first visit.
void main() {
  setUp(_builds.clear);

  for (final kind in _Kind.values) {
    group('${kind.name}:', () {
      testWidgets('lazyLoad: false builds every tab before the first switch', (tester) async {
        final observer = _TabObserver();
        final router = _buildRouter(kind, lazyLoad: false);
        await pumpRouterApp(tester, router, observers: () => [observer]);

        expect(_builds, {for (final name in _kTabNames) name: 1});
        expect(observer.initialized, _kTabNames);
        expect(router.innerRouterOf<TabsRouter>('TabsRoute')!.activeIndex, 0);

        router.innerRouterOf<TabsRouter>('TabsRoute')!.setActiveIndex(2);
        await tester.pumpAndSettle();

        expect(find.text(_kTabNames[2]), findsOneWidget);
        expect(_builds, {for (final name in _kTabNames) name: 1});
        expect(observer.initialized, _kTabNames);
        expect(observer.changed, [_kTabNames[2]]);
      });

      testWidgets('by default only the active tab is built before the first switch', (tester) async {
        final router = _buildRouter(kind);
        await pumpRouterApp(tester, router);

        expect(_builds, {_kTabNames[0]: 1});
      });
    });
  }
}

enum _Kind { tabBar, pageView }

const _kTabNames = ['NewsRoute', 'FeedRoute', 'ProfileRoute'];

// How often each tab's page was built.
final _builds = <String, int>{};

RootStackRouter _buildRouter(_Kind kind, {bool? lazyLoad}) {
  final routes = [for (final name in _kTabNames) _Route(name)];
  return RootStackRouter.build(
    routes: [
      AutoRoute(
        page: PageInfo(
          'TabsRoute',
          builder: (_) => switch ((kind, lazyLoad)) {
            (.tabBar, final bool lazyLoad) => AutoTabsRouter.tabBar(routes: routes, lazyLoad: lazyLoad),
            (.tabBar, null) => AutoTabsRouter.tabBar(routes: routes),
            (.pageView, final bool lazyLoad) => AutoTabsRouter.pageView(routes: routes, lazyLoad: lazyLoad),
            (.pageView, null) => AutoTabsRouter.pageView(routes: routes),
          },
        ),
        path: '/',
        children: [for (final name in _kTabNames) AutoRoute(page: _page(name), path: name)],
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
    _builds.update(widget.name, (count) => count + 1, ifAbsent: () => 1);
  }

  @override
  Widget build(BuildContext context) => Text(widget.name);
}

class _TabObserver extends AutoRouterObserver {
  final initialized = <String>[];
  final changed = <String>[];

  @override
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) => initialized.add(route.name);

  @override
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) => changed.add(route.name);
}

class _Route extends PageRouteInfo<void> {
  const _Route(super.name);
}
