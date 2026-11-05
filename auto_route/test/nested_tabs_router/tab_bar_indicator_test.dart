import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // Guards https://github.com/Milad-Akarie/auto_route_library/issues/2012
  // Steps: AutoTabsRouter.tabBar with three routes; its builder puts the
  // TabBar in a pinned, floating, snapping SliverAppBar of a NestedScrollView
  // whose body is the tab view. Tap the third tab, then the first, then swipe
  // to the second.
  // Reported: the tab indicator shakes while it moves.
  // Should: the TabController's animation, which places the indicator, moves
  // one way only, frame after frame, and ends on the tapped tab.
  testWidgets('the tab indicator moves one way to the tapped tab in a NestedScrollView', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _HomeRoute.page,
          path: '/',
          initial: true,
          children: [
            AutoRoute(page: _AllNotesTabRoute.page, path: 'all'),
            AutoRoute(page: _PinnedTabRoute.page, path: 'pinned'),
            AutoRoute(page: _FoldersTabRoute.page, path: 'folders'),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    final tabController = tester.widget<TabBar>(find.byType(TabBar)).controller!;

    Future<List<double>> framesUntilSettled() async {
      final values = [tabController.animation!.value];
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        values.add(tabController.animation!.value);
      }
      await tester.pumpAndSettle();
      return values;
    }

    // A swipe can leave the offset a hair short of the page, as Flutter's own TabBarView does.
    void expectOneWay(List<double> values, double end, {double tolerance = 1e-6}) {
      final [first, ...rest] = values;
      final rising = end > first;
      var previous = first;
      for (final (index, value) in rest.indexed) {
        final step = value - previous;
        expect(rising ? step >= -1e-9 : step <= 1e-9, isTrue, reason: 'frame ${index + 1} of $values');
        previous = value;
      }
      expect(values.lastOrNull, closeTo(end, tolerance));
    }

    await tester.tap(find.byType(Tab).at(2));
    expectOneWay(await framesUntilSettled(), 2);
    expect(find.text('${_FoldersTabRoute.name} 0'), findsOneWidget);

    await tester.tap(find.byType(Tab).at(0));
    expectOneWay(await framesUntilSettled(), 0);
    expect(find.text('${_AllNotesTabRoute.name} 0'), findsOneWidget);

    final swipe = await tester.startGesture(tester.getCenter(find.text('${_AllNotesTabRoute.name} 3')));
    final values = [tabController.animation!.value];
    // Drags 60% of the screen width, so the page settles on the next tab.
    final step = tester.view.physicalSize.width / tester.view.devicePixelRatio * 0.6 / 30;
    for (var i = 0; i < 30; i++) {
      await swipe.moveBy(Offset(-step, 0));
      await tester.pump(const Duration(milliseconds: 16));
      values.add(tabController.animation!.value);
    }
    await swipe.up();
    values.addAll((await framesUntilSettled()).skip(1));
    expectOneWay(values, 1, tolerance: 0.01);
    expect(tabController.index, 1);
  });
}

class _HomeRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_HomeRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => AutoTabsRouter.tabBar(
      routes: const [_AllNotesTabRoute(), _PinnedTabRoute(), _FoldersTabRoute()],
      builder: (context, child, tabController) => Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              snap: true,
              floating: true,
              pinned: true,
              title: const Text('Notes'),
              toolbarHeight: 60,
              expandedHeight: 110,
              bottom: TabBar(
                controller: tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.notes, size: 14), height: 50),
                  Tab(icon: Icon(Icons.push_pin, size: 14), height: 50),
                  Tab(icon: Icon(Icons.folder, size: 14), height: 50),
                ],
              ),
            ),
          ],
          body: child,
        ),
      ),
    ),
  );
}

PageInfo _listPage(String name) => .new(
  name,
  builder: (_) => ListView.builder(itemCount: 30, itemBuilder: (_, index) => ListTile(title: Text('$name $index'))),
);

class _AllNotesTabRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_AllNotesTabRoute';
  static PageInfo page = _listPage(name);
}

class _PinnedTabRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_PinnedTabRoute';
  static PageInfo page = _listPage(name);
}

class _FoldersTabRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_FoldersTabRoute';
  static PageInfo page = _listPage(name);
}
