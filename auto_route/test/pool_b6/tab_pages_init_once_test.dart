import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1366
// Setup, as in the report (auto_route 6): the router is made once, outside
// the widget tree, as an injected singleton with its own navigator key, and
// the app gives MaterialApp.router its delegate and route parser. LoginRoute
// is the initial route and has a guard that, for a signed-in user, navigates
// to HomeRoute and does not call next(). Home is a route with the tab pages
// as children. Its State reads a flag in initState and builds AutoTabsRouter
// with three tab routes in build, and a builder that wraps the child in a
// scaffold with a bottom bar reading AutoTabsRouter.of(context).activeIndex
// and calling setActiveIndex.
// Steps: open the app signed in, which the guard sends to Home, then switch to
// each tab and back.
// Reported: each tab page's initState runs ten or more times on every tab
// switch and on the first build.
// Should: a tab page's initState runs once, when the tab is first shown.
void main() {
  late RootStackRouter router;

  setUp(() {
    _initCounts.clear();
    _builderCalls = 0;
    router = RootStackRouter.build(
      navigatorKey: GlobalKey(),
      routes: [
        NamedRouteDef(
          name: 'LoginRoute',
          path: '/',
          initial: true,
          guards: [
            AutoRouteGuard.simple((_, stack) {
              // The report's guard: a signed-in user goes to Home.
              unawaited(stack.navigate(const NamedRoute('HomeRoute')));
            }),
          ],
          builder: (_, _) => const Scaffold(body: Text('Login')),
        ),
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/home',
          builder: (_, _) => const _Home(),
          children: [
            for (final name in _tabNames)
              NamedRouteDef(
                name: name,
                path: name.toLowerCase(),
                builder: (_, _) => _InitCountPage(name),
              ),
          ],
        ),
      ],
    );
  });

  testWidgets('A tab page runs initState once on the first build', (
    tester,
  ) async {
    await pumpRouterApp(tester, router);

    expect(find.text('One page'), findsOneWidget);
    expect(_initCounts, {'One': 1});
  });

  testWidgets('Switching through the tabs builds each page once', (
    tester,
  ) async {
    await pumpRouterApp(tester, router);
    final tabs = router.innerRouterOf<TabsRouter>('HomeRoute')!;
    final builderCallsAfterFirstBuild = _builderCalls;

    for (final index in [1, 2, 0, 1, 2]) {
      tabs.setActiveIndex(index);
      await tester.pumpAndSettle();
    }

    expect(_initCounts, {'One': 1, 'Two': 1, 'Three': 1});
    expect(
      _builderCalls - builderCallsAfterFirstBuild,
      lessThanOrEqualTo(10),
      reason: 'five tab switches should build the tabs builder a few times',
    );
  });
}

const _tabNames = ['One', 'Two', 'Three'];

final _initCounts = <String, int>{};
var _builderCalls = 0;

class _Home extends StatefulWidget {
  const new();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  late final List<PageRouteInfo> _tabs;

  @override
  void initState() {
    super.initState();
    // The report picks its tabs from an injected config here.
    _tabs = const [NamedRoute('One'), NamedRoute('Two'), NamedRoute('Three')];
  }

  @override
  Widget build(BuildContext context) => AutoTabsRouter(
    routes: _tabs,
    builder: (context, child) {
      _builderCalls++;
      return Scaffold(
        body: child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: AutoTabsRouter.of(context).activeIndex,
          onTap: AutoTabsRouter.of(context).setActiveIndex,
          items: [
            for (final name in _tabNames)
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: name,
              ),
          ],
        ),
      );
    },
  );
}

class _InitCountPage extends StatefulWidget {
  const new(this.name);

  final String name;

  @override
  State<_InitCountPage> createState() => _InitCountPageState();
}

class _InitCountPageState extends State<_InitCountPage> {
  @override
  void initState() {
    super.initState();
    _initCounts.update(widget.name, (count) => count + 1, ifAbsent: () => 1);
  }

  @override
  Widget build(BuildContext context) => Text('${widget.name} page');
}
