import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Back acts on the tab on screen, not on a hidden one.
// https://github.com/Milad-Akarie/auto_route_library/issues/2225
// Headless test: auto_route/test/nested_tabs_router/back_in_tabs_test.dart
//
// Setup, as in the report, which used the package's mobile example app: the
// app's first page holds an AutoTabsRouter with a books tab and a profile
// tab, each with its own stack.
// Steps: push a page in one tab, switch tabs, and go back: system back (on
// Android through the activity, see systemBack), or the iOS edge swipe (run
// with the iOS page transitions on every platform).
// Reported: back sometimes popped the tab's page and sometimes left the
// app, depending on what the other tabs held.
// Should: back pops the pages of the tab on screen until it reaches the
// tab's first page; there Android leaves the app, whatever the other tabs
// hold.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _homePage,
          path: '/',
          children: [
            AutoRoute(
              page: const EmptyShellRoute('BooksTab'),
              path: 'books',
              children: [
                AutoRoute(page: _page('BookListRoute'), path: ''),
                AutoRoute(page: _page('BookDetailsRoute'), path: ':id'),
              ],
            ),
            AutoRoute(
              page: const EmptyShellRoute('ProfileTab'),
              path: 'profile',
              children: [
                AutoRoute(page: _page('ProfileRoute'), path: ''),
                AutoRoute(page: _page('MyBooksRoute'), path: 'my-books'),
              ],
            ),
          ],
        ),
      ],
    );
  });

  Future<TabsRouter> pumpApp(WidgetTester tester, {ThemeData? theme}) async {
    await pumpRouterApp(tester, router, theme: theme);
    return router.innerRouterOf<TabsRouter>(_homePage.name)!;
  }

  Future<void> showTab(WidgetTester tester, TabsRouter tabs, int index) async {
    tabs.setActiveIndex(index);
    await tester.pumpAndSettle();
  }

  Future<void> pushInTab(
    WidgetTester tester,
    TabsRouter tabs,
    int index,
    String name,
  ) async {
    unawaited(tabs.stackRouterOfIndex(index)!.push(_Route(name)));
    await tester.pumpAndSettle();
  }

  List<String?> stackOf(TabsRouter tabs, int index) => [
    for (final page in tabs.stackRouterOfIndex(index)!.stack) page.name,
  ];

  testWidgets(
    'system back in a tab with a pushed page pops it after a tab switch',
    (tester) async {
      final tabs = await pumpApp(tester);
      await pushInTab(tester, tabs, 0, 'BookDetailsRoute');
      await showTab(tester, tabs, 1);
      await showTab(tester, tabs, 0);

      await systemBack(tester);

      expect(stackOf(tabs, 0), ['BookListRoute']);
    },
  );

  // Pressing back here would leave the app, so this checks what Android
  // would do instead.
  testWidgets(
    'on a tab at its first page, Android leaves the app instead of popping the '
    "other tab's page",
    (tester) async {
      final tabs = await pumpApp(tester);
      await pushInTab(tester, tabs, 0, 'BookDetailsRoute');
      await showTab(tester, tabs, 1);

      expect(await androidSendsBackToFlutter(), anyOf(isNull, isFalse));
      expect(stackOf(tabs, 0), ['BookListRoute', 'BookDetailsRoute']);
    },
  );

  testWidgets('the iOS back swipe pops only the page of the tab on screen', (
    tester,
  ) async {
    final tabs = await pumpApp(tester, theme: ThemeData(platform: .iOS));
    await pushInTab(tester, tabs, 0, 'BookDetailsRoute');
    await showTab(tester, tabs, 1);
    await pushInTab(tester, tabs, 1, 'MyBooksRoute');

    await swipeBack(tester);

    expect(stackOf(tabs, 1), ['ProfileRoute']);
    expect(stackOf(tabs, 0), ['BookListRoute', 'BookDetailsRoute']);
  });

  testWidgets(
    'system back pops a page pushed in a tab while it was hidden, once it '
    'shows',
    (tester) async {
      final tabs = await pumpApp(tester);
      await showTab(tester, tabs, 1);
      await pushInTab(tester, tabs, 0, 'BookDetailsRoute');
      await showTab(tester, tabs, 0);

      await systemBack(tester);

      expect(stackOf(tabs, 0), ['BookListRoute']);
    },
  );
}

final _homePage = PageInfo(
  'HomeRoute',
  builder: (_) =>
      const AutoTabsRouter(routes: [_Route('BooksTab'), _Route('ProfileTab')]),
);

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
