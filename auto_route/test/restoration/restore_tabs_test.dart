import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'restoration_test_utils.dart';

void main() {
  // Flutter's state restoration doesn't run on the web, so the routers save
  // their pages only off the web.
  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(page: page('SignUpRoute'), initial: true),
      AutoRoute(
        page: _bottomNavigationPage,
        children: [
          AutoRoute(
            path: 'home',
            page: const EmptyShellRoute('HomeTabRoute'),
            initial: true,
            children: [
              AutoRoute(page: page('HomeRoute'), initial: true),
              AutoRoute(page: page('InternalRoute')),
            ],
          ),
          AutoRoute(
            path: 'transitions',
            page: const EmptyShellRoute('TransitionsTabRoute'),
            children: [
              AutoRoute(page: page('TransitionsRoute'), initial: true),
              AutoRoute(page: page('TransitionDetailsRoute')),
            ],
          ),
          AutoRoute(path: 'settings', page: page('SettingsRoute')),
        ],
      ),
    ],
  );

  TabsRouter tabsRouter() => RestorableRouterApp.router.innerRouterOf<TabsRouter>('BottomNavigationRoute')!;

  Future<void> selectTab(WidgetTester tester, int index) async {
    tabsRouter().setActiveIndex(index);
    await tester.pumpAndSettle();
  }

  // https://github.com/Milad-Akarie/auto_route_library/issues/2041
  // Three tabs in an AutoTabsRouter; the first holds a nested stack. Call
  // replace(BottomNavigationRoute()), push(InternalRoute()) in the first
  // tab, switch to the second tab, then let the platform end and restore
  // the app. The second tab should show, and the first tab should still
  // show InternalRoute, not HomeRoute.
  testWidgets('a tab that is not active keeps its stack after restoration', (tester) async {
    await tester.pumpWidget(RestorableRouterApp(buildRouter));
    await tester.pumpAndSettle();
    RestorableRouterApp.router.replace(const NamedRoute('BottomNavigationRoute'));
    await tester.pumpAndSettle();
    RestorableRouterApp.router.push(const NamedRoute('InternalRoute'));
    await tester.pumpAndSettle();
    expect(find.text('InternalRoute'), findsOneWidget);
    await selectTab(tester, 1);

    await tester.restartAndRestore();
    await tester.pumpAndSettle();
    expect(tabsRouter().activeIndex, 1);
    expect(find.text('TransitionsRoute'), findsOneWidget);
    await selectTab(tester, 0);
    expect(find.text('HomeRoute'), findsNothing);
    expect(find.text('InternalRoute'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('HomeRoute'), findsOneWidget);
  }, skip: kIsWeb);

  // https://github.com/Milad-Akarie/auto_route_library/issues/2099
  // Go a few pages deep in one tab, switch to another tab and go deeper
  // there, then let the platform end and restore the app. Both tabs should
  // keep their stacks, not only the last visited one.
  testWidgets('every tab keeps its stack after restoration', (tester) async {
    await tester.pumpWidget(RestorableRouterApp(buildRouter));
    await tester.pumpAndSettle();
    RestorableRouterApp.router.replace(const NamedRoute('BottomNavigationRoute'));
    await tester.pumpAndSettle();
    RestorableRouterApp.router.push(const NamedRoute('InternalRoute'));
    await tester.pumpAndSettle();
    RestorableRouterApp.router.push(const NamedRoute('InternalRoute'));
    await tester.pumpAndSettle();
    await selectTab(tester, 1);
    RestorableRouterApp.router.push(const NamedRoute('TransitionDetailsRoute'));
    await tester.pumpAndSettle();
    await selectTab(tester, 2);

    await tester.restartAndRestore();
    await tester.pumpAndSettle();
    expect(tabsRouter().activeIndex, 2);
    expect(find.text('SettingsRoute'), findsOneWidget);
    expect(RestorableRouterApp.router.currentHierarchy(), const [
      HierarchySegment(
        'BottomNavigationRoute',
        children: [
          HierarchySegment(
            'HomeTabRoute',
            children: [
              HierarchySegment('HomeRoute'),
              HierarchySegment('InternalRoute'),
              HierarchySegment('InternalRoute'),
            ],
          ),
          HierarchySegment(
            'TransitionsTabRoute',
            children: [HierarchySegment('TransitionsRoute'), HierarchySegment('TransitionDetailsRoute')],
          ),
          HierarchySegment('SettingsRoute'),
        ],
      ),
    ]);

    await selectTab(tester, 1);
    expect(find.text('TransitionDetailsRoute'), findsOneWidget);
    await selectTab(tester, 0);
    expect(find.text('InternalRoute'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('InternalRoute'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('HomeRoute'), findsOneWidget);
  }, skip: kIsWeb);
}

final _bottomNavigationPage = PageInfo(
  'BottomNavigationRoute',
  builder: (_) => AutoTabsRouter(
    routes: const [NamedRoute('HomeTabRoute'), NamedRoute('TransitionsTabRoute'), NamedRoute('SettingsRoute')],
    builder: (_, child) => child,
  ),
);
