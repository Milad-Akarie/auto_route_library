import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/155034:
// a DropdownMenu opened in a nested navigator goes under the bottom bar.
// Setup: an 800 x 400 screen (a phone in landscape); a Scaffold with a
// NavigationBar whose body is a nested Navigator; its page holds a
// DropdownMenu of eight entries a little above the middle. The same with an
// AutoTabsScaffold and a nested AutoRouter in the tab.
// Steps: open the menu.
// Today the menu opens in the nearest Overlay, the nested navigator's
// (widgets/raw_menu_anchor.dart, unless useRootOverlay is set), runs past
// the bottom of that navigator, and the NavigationBar, painted after the
// body, covers its last entries: a tap there reaches the bar. MenuAnchor
// has a useRootOverlay switch; DropdownMenu doesn't. Making the root overlay
// the default was reverted (flutter/flutter#159906).
// If this test fails after a Flutter upgrade, the menu now shows over the
// bar: drop this canary.
void main() {
  Widget menuPage() => Scaffold(
    body: Align(
      alignment: const Alignment(0, -0.2),
      child: DropdownMenu<int>(
        dropdownMenuEntries: [
          for (var i = 0; i < 8; i++)
            DropdownMenuEntry(value: i, label: 'Entry $i'),
        ],
      ),
    ),
  );

  const destinations = [
    NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
  ];

  Future<(bool, bool)> openMenu(WidgetTester tester) async {
    await tester.tap(find.byType(DropdownMenu<int>));
    await tester.pumpAndSettle();
    final lastEntry = find.text('Entry 7').last;
    final entryBox = tester.renderObject(lastEntry);
    final hits = tester.hitTestOnBinding(tester.getCenter(lastEntry));

    return (
      tester.getTopLeft(lastEntry).dy >
          tester.getTopLeft(find.byType(NavigationBar)).dy,
      hits.path.any((entry) => identical(entry.target, entryBox)),
    );
  }

  void useLandscapePhone(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(800, 400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('a plain nested menu opens under the bar', (tester) async {
    useLandscapePhone(tester);
    final pages = [MaterialPage<void>(child: menuPage())];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: NavigationBar(destinations: destinations),
          body: Navigator(pages: pages, onDidRemovePage: pages.remove),
        ),
      ),
    );

    expect(await openMenu(tester), (true, false));
  });

  testWidgets('an auto_route tab menu opens under the bar', (tester) async {
    useLandscapePhone(tester);
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'ShellRoute',
            builder: (_) => AutoTabsScaffold(
              routes: const [NamedRoute('MenuTab'), NamedRoute('OtherTab')],
              bottomNavigationBuilder: (_, tabsRouter) => NavigationBar(
                selectedIndex: tabsRouter.activeIndex,
                destinations: destinations,
              ),
            ),
          ),
          children: [
            AutoRoute(
              path: 'menu',
              page: PageInfo('MenuTab', builder: (_) => const AutoRouter()),
              children: [
                AutoRoute(
                  path: '',
                  page: PageInfo('MenuRoute', builder: (_) => menuPage()),
                ),
              ],
            ),
            AutoRoute(
              path: 'other',
              page: PageInfo('OtherTab', builder: (_) => const Text('Other')),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);

    expect(await openMenu(tester), (true, false));
  });
}
