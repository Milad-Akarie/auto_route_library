import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  tearDownAll(_routesNotifier.dispose);
  _TabsKind.values.forEach(_runRemovedTabTests);
}

void _runRemovedTabTests(_TabsKind kind) {
  // Reproduces https://github.com/Milad-Akarie/auto_route_library/issues/1786
  // Steps: an AutoTabsRouter.pageView has routes [first, second, third].
  // Open the second page, then the third, then rebuild with [first, third].
  // Happens: the removed second page shows.
  // Should: the third page shows and keeps its state.
  testWidgets('${kind.name}: removing the page before the active page keeps the active page shown', (tester) async {
    _tabsKind = kind;
    _routesNotifier.value = const [_FirstTabRoute(), _SecondTabRoute(), _ThirdTabRoute()];
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
    final tabsRouter = router.innerRouterOf<TabsRouter>(_TabsHostRoute.name)!..setActiveIndex(1);
    await tester.pumpAndSettle();
    tabsRouter.setActiveIndex(2);
    await tester.pumpAndSettle();
    await tester.tap(find.text('${_ThirdTabRoute.name}: add one'));
    await tester.pumpAndSettle();
    expect(find.text('${_ThirdTabRoute.name} taps: 1'), findsOneWidget);

    _routesNotifier.value = const [_FirstTabRoute(), _ThirdTabRoute()];
    await tester.pumpAndSettle();
    expect(find.text('${_SecondTabRoute.name} taps: 0'), findsNothing);
    expect(
      find.text('${_ThirdTabRoute.name} taps: 1'),
      findsOneWidget,
      reason: 'after _routesNotifier.value = const [_FirstTabRoute(), _ThirdT',
    );
    expect(tester.getTopLeft(find.text('${_ThirdTabRoute.name} taps: 1')).dx, 0);
    expect(tabsRouter.activeIndex, 1);

    // The first page is still one step back.
    tabsRouter.setActiveIndex(0);
    await tester.pumpAndSettle();
    expect(find.text('${_FirstTabRoute.name} taps: 0'), findsOneWidget);
    expect(tester.getTopLeft(find.text('${_FirstTabRoute.name} taps: 0')).dx, 0);
  });
}

enum _TabsKind { indexedStack, pageView, tabBar, builder }

_TabsKind _tabsKind = .indexedStack;

final _routesNotifier = ValueNotifier<List<PageRouteInfo>>(const []);

class _TabsHostRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_TabsHostRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => ValueListenableBuilder<List<PageRouteInfo>>(
      valueListenable: _routesNotifier,
      builder: (context, routes, _) => switch (_tabsKind) {
        .indexedStack => AutoTabsRouter(routes: routes),
        .pageView => AutoTabsRouter.pageView(routes: routes),
        .tabBar => AutoTabsRouter.tabBar(routes: routes),
        .builder => AutoTabsRouter.builder(
          routes: routes,
          builder: (context, children, tabsRouter) => IndexedStack(index: tabsRouter.activeIndex, children: children),
        ),
      },
    ),
  );
}

class _FirstTabRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_FirstTabRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const _CounterPage(name));
}

class _SecondTabRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_SecondTabRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const _CounterPage(name));
}

class _ThirdTabRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_ThirdTabRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const _CounterPage(name));
}

// A tab page with a tap counter, the state the active page must keep.
class _CounterPage extends StatefulWidget {
  const new(this.label);

  final String label;

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  var _taps = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: .start,
        children: [
          Text('${widget.label} taps: $_taps'),
          TextButton(onPressed: () => setState(() => _taps++), child: Text('${widget.label}: add one')),
        ],
      ),
    );
  }
}
