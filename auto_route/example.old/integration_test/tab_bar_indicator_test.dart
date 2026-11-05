import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// The tab indicator of AutoTabsRouter.tabBar in a NestedScrollView moves one way to the tapped tab.
// https://github.com/Milad-Akarie/auto_route_library/issues/2012
// Headless test: auto_route/test/nested_tabs_router/tab_bar_indicator_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: the TabBar sits in a pinned, floating, snapping SliverAppBar of a
  // NestedScrollView whose body is the tab view. Tap the third tab, the
  // first, then swipe to the second.
  // Should: the TabController's animation moves one way only and ends on the
  // tapped tab.
  testWidgets(
    'the tab indicator moves one way to the tapped tab in a NestedScrollView',
    (tester) async {
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
      await pumpRouterConfigApp(
        tester,
        router.config(deepLinkBuilder: (_) => DeepLink.defaultPath),
      );
      final tabController = tester
          .widget<TabBar>(find.byType(TabBar))
          .controller!;

      Future<List<double>> framesUntilSettled() async {
        final values = <double>[tabController.animation!.value];
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          values.add(tabController.animation!.value);
        }
        await tester.pumpAndSettle();
        return values;
      }

      // A swipe can leave the offset a hair short of the page, as Flutter's own TabBarView does.
      void expectOneWay(
        List<double> values,
        double end, {
        double tolerance = 1e-6,
      }) {
        final rising = end > values.first;
        for (var i = 1; i < values.length; i++) {
          final step = values[i] - values[i - 1];
          expect(
            rising ? step >= -1e-9 : step <= 1e-9,
            isTrue,
            reason: 'frame $i of $values',
          );
        }
        expect(values.last, closeTo(end, tolerance));
      }

      await tester.tap(find.byType(Tab).at(2));
      expectOneWay(await framesUntilSettled(), 2);
      expect(find.text('${_FoldersTabRoute.name} 0'), findsOneWidget);

      await tester.tap(find.byType(Tab).at(0));
      expectOneWay(await framesUntilSettled(), 0);
      expect(find.text('${_AllNotesTabRoute.name} 0'), findsOneWidget);

      final swipe = await tester.startGesture(
        tester.getCenter(find.text('${_AllNotesTabRoute.name} 3')),
      );
      final values = <double>[tabController.animation!.value];
      // Drags 60% of the screen width, so the page settles on the next tab.
      final step =
          tester.view.physicalSize.width /
          tester.view.devicePixelRatio *
          0.6 /
          30;
      for (var i = 0; i < 30; i++) {
        await swipe.moveBy(Offset(-step, 0));
        await tester.pump(const Duration(milliseconds: 16));
        values.add(tabController.animation!.value);
      }
      await swipe.up();
      values.addAll((await framesUntilSettled()).skip(1));
      expectOneWay(values, 1, tolerance: 0.01);
      expect(tabController.index, 1);
    },
  );
}

class _HomeRoute extends PageRouteInfo<void> {
  const _HomeRoute() : super(name);

  static const String name = '_HomeRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => AutoTabsRouter.tabBar(
      routes: const [
        _AllNotesTabRoute(),
        _PinnedTabRoute(),
        _FoldersTabRoute(),
      ],
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
  builder: (_) => ListView.builder(
    itemCount: 30,
    itemBuilder: (_, index) => ListTile(title: Text('$name $index')),
  ),
);

class _AllNotesTabRoute extends PageRouteInfo<void> {
  const _AllNotesTabRoute() : super(name);

  static const String name = '_AllNotesTabRoute';
  static PageInfo page = _listPage(name);
}

class _PinnedTabRoute extends PageRouteInfo<void> {
  const _PinnedTabRoute() : super(name);

  static const String name = '_PinnedTabRoute';
  static PageInfo page = _listPage(name);
}

class _FoldersTabRoute extends PageRouteInfo<void> {
  const _FoldersTabRoute() : super(name);

  static const String name = '_FoldersTabRoute';
  static PageInfo page = _listPage(name);
}
