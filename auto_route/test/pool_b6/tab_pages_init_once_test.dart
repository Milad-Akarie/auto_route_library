import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1366
// Setup, as in the report (auto_route 6): a Home page, itself a route with
// the tab pages as children, builds AutoTabsRouter with three tab routes in
// its State's build, and a builder that wraps the child in a scaffold with a
// bottom bar reading AutoTabsRouter.of(context).activeIndex and calling
// setActiveIndex. (The report's login guard is left out: it only sends the
// signed-in user to Home, which a deep link does here.)
// Steps: open Home, then switch to each tab and back.
// Reported: each tab page's initState runs ten or more times on every tab
// switch and on the first build.
// Should: a tab page's initState runs once, when the tab is first shown.
void main() {
  late RootStackRouter router;

  setUp(() {
    _initCounts.clear();
    _builderCalls = 0;
    router = RootStackRouter.build(
      routes: [
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
    await pumpRouterConfigApp(
      tester,
      router.config(deepLinkBuilder: (_) => const DeepLink.path('/home')),
    );

    expect(find.text('One page'), findsOneWidget);
    expect(_initCounts, {'One': 1});
  });

  testWidgets('Switching through the tabs builds each page once', (
    tester,
  ) async {
    await pumpRouterConfigApp(
      tester,
      router.config(deepLinkBuilder: (_) => const DeepLink.path('/home')),
    );
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

class _Home extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => AutoTabsRouter(
    routes: const [NamedRoute('One'), NamedRoute('Two'), NamedRoute('Three')],
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
