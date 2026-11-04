import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

/// Weak references to the state of every [_TrackedPage] built, by its label.
final _pageStates = <String, WeakReference<State>>{};

/// A page that records a weak reference to its state, to check that nothing
/// holds the state once the page leaves the stack.
class _TrackedPage extends StatefulWidget {
  const _TrackedPage(this.label);

  final String label;

  @override
  State<_TrackedPage> createState() => _TrackedPageState();
}

class _TrackedPageState extends State<_TrackedPage> {
  @override
  void initState() {
    super.initState();
    _pageStates[widget.label] = WeakReference(this);
  }

  @override
  Widget build(BuildContext context) => Text(widget.label);
}

PageInfo _trackedPage(String name) => .new(name, builder: (_) => _TrackedPage(name));

final _homePage = PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute'));
final PageInfo _detailPage = _trackedPage('DetailRoute');
final _stackHostPage = PageInfo('StackHostRoute', builder: (_) => const AutoRouter());
final PageInfo _tab1Page = _trackedPage('Tab1Route');
final PageInfo _tab2Page = _trackedPage('Tab2Route');

PageInfo _tabsHostPage(String tabsType) => .new(
  'TabsHostRoute',
  builder: (_) {
    const routes = [NamedRoute('Tab1Route'), NamedRoute('Tab2Route')];
    return switch (tabsType) {
      'PageView' => const AutoTabsRouter.pageView(routes: routes),
      'TabBar' => AutoTabsRouter.tabBar(routes: routes, builder: (_, child, _) => child),
      _ => const AutoTabsRouter(routes: routes),
    };
  },
);

RootStackRouter _buildRouter({String tabsType = 'IndexedStack'}) => .build(
  routes: [
    AutoRoute(path: '/', page: _homePage),
    AutoRoute(path: '/detail', page: _detailPage),
    AutoRoute(
      path: '/stack',
      page: _stackHostPage,
      children: [AutoRoute(path: '', page: _trackedPage('StackChildRoute'))],
    ),
    AutoRoute(
      path: '/tabs',
      page: _tabsHostPage(tabsType),
      children: [
        AutoRoute(path: 'tab1', page: _tab1Page),
        AutoRoute(path: 'tab2', page: _tab2Page),
      ],
    ),
  ],
);

/// Pumps until settled, then forces full garbage collections until every one
/// of [references] is cleared, for at most 10 rounds.
///
/// One round can fall short on a busy machine: a collection that began before
/// the pop still counts as one of its cycles. Gives up quietly after the last
/// round, so the test's own expects report what is still held.
Future<void> _settleAndCollect(WidgetTester tester, List<WeakReference<Object>> references) async {
  await tester.pumpAndSettle();
  for (var round = 0; round < 10 && references.any((reference) => reference.target != null); round++) {
    await tester.runAsync(() => forceGC(fullGcCycles: 2));
  }
}

void main() {
  setUp(_pageStates.clear);

  // Steps: push DetailRoute, pop it, then force a garbage collection.
  // Should: nothing holds the popped page's RouteData or its state.
  testWidgets(
    'A popped page releases its RouteData and state',
    (tester) async {
      final router = _buildRouter();
      await pumpRouterApp(tester, router);
      unawaited(router.pushPath('/detail'));
      await tester.pumpAndSettle();
      expect(find.text('DetailRoute'), findsOneWidget);
      final routeData = WeakReference(router.current);

      router.pop();
      await _settleAndCollect(tester, [routeData, _pageStates['DetailRoute']!]);
      expect(find.text('DetailRoute'), findsNothing);
      expect(routeData.target, isNull);
      expect(_pageStates['DetailRoute']!.target, isNull);
    },
    // Web has no reachabilityBarrier to wait for a full collection on.
    skip: kIsWeb,
  );

  // Steps: push and pop DetailRoute 50 times, then force a garbage collection.
  // Should: no state of a popped page stays in memory.
  testWidgets('Pushing and popping a page many times keeps no popped page', (tester) async {
    final router = _buildRouter();
    await pumpRouterApp(tester, router);
    final states = <WeakReference<State>>[];
    for (var i = 0; i < 50; i++) {
      unawaited(router.pushPath('/detail'));
      await tester.pumpAndSettle();
      states.add(_pageStates['DetailRoute']!);
      router.pop();
      await tester.pumpAndSettle();
    }
    await _settleAndCollect(tester, states);
    expect(states.where((state) => state.target != null), isEmpty);
  }, skip: kIsWeb);

  // Steps: open StackHostRoute, whose page holds an AutoRouter, then pop it.
  // Should: nothing holds the nested router, its RouteData or its page's state.
  testWidgets('A popped nested router releases its controller and pages', (tester) async {
    final router = _buildRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.pushPath('/stack'));
    await tester.pumpAndSettle();
    expect(find.text('StackChildRoute'), findsOneWidget);
    final nested = WeakReference(router.innerRouterOf<StackRouter>('StackHostRoute')!);
    final childData = WeakReference(nested.target!.current);

    router.pop();
    await _settleAndCollect(tester, [nested, childData, _pageStates['StackChildRoute']!]);
    expect(router.childControllers, isEmpty);
    expect(nested.target, isNull);
    expect(childData.target, isNull);
    expect(_pageStates['StackChildRoute']!.target, isNull);
  }, skip: kIsWeb);

  for (final tabsType in ['IndexedStack', 'PageView', 'TabBar']) {
    // Steps: open TabsHostRoute, switch tabs 20 times, then pop the host.
    // Should: nothing holds the tabs router or the state of either tab.
    testWidgets('A popped $tabsType tabs router releases its controller and tabs', (tester) async {
      final router = _buildRouter(tabsType: tabsType);
      await pumpRouterApp(tester, router);
      unawaited(router.pushPath('/tabs'));
      await tester.pumpAndSettle();
      final tabsRouter = WeakReference(router.innerRouterOf<TabsRouter>('TabsHostRoute')!);
      for (var i = 0; i < 20; i++) {
        tabsRouter.target!.setActiveIndex(i.isEven ? 1 : 0);
        await tester.pumpAndSettle();
      }
      expect(find.text('Tab1Route'), findsOneWidget);
      expect(_pageStates.keys, containsAll(['Tab1Route', 'Tab2Route']));

      router.pop();
      await _settleAndCollect(tester, [tabsRouter, _pageStates['Tab1Route']!, _pageStates['Tab2Route']!]);
      expect(router.childControllers, isEmpty);
      expect(tabsRouter.target, isNull);
      expect(_pageStates['Tab1Route']!.target, isNull);
      expect(_pageStates['Tab2Route']!.target, isNull);
    }, skip: kIsWeb);
  }
}
