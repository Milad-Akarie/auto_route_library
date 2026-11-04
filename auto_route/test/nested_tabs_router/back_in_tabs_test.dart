import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';

// Reproduction for https://github.com/Milad-Akarie/auto_route_library/issues/2225
// Setup, as in the report, which used the package's mobile example app: the
// app's first page holds an AutoTabsRouter with a books tab and a profile
// tab, each with its own stack (a list and a details page, a profile and a
// my-books page).
// Steps: push a page in one tab, switch tabs, and go back: system back,
// Android's predictive back gesture, or the iOS edge swipe.
// Happens: back acts on a hidden tab. On a tab at its first page, Flutter
// tells Android the app handles back, and back pops the other tab's page
// out of sight instead of leaving the app; predictive back on a tab with a
// page pushed pops that page and the hidden tab's page too.
// Should, as the report expects: back pops the pages of the tab on screen
// until it reaches the tab's first page, then leaves the app, whatever the
// other tabs hold.
void main() {
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

  late FrameworkHandlesBackRecorder frameworkHandlesBack;

  Future<TabsRouter> pumpApp(WidgetTester tester, {ThemeData? theme}) async {
    frameworkHandlesBack = FrameworkHandlesBackRecorder()..listen(tester);
    await tester.pumpWidget(MaterialApp.router(theme: theme, routerConfig: router.config()));
    await tester.pumpAndSettle();
    return router.innerRouterOf<TabsRouter>(_homePage.name)!;
  }

  Future<void> showTab(WidgetTester tester, TabsRouter tabs, int index) async {
    tabs.setActiveIndex(index);
    await tester.pumpAndSettle();
  }

  Future<void> pushInTab(WidgetTester tester, TabsRouter tabs, int index, String name) async {
    unawaited(tabs.stackRouterOfIndex(index)!.push(_Route(name)));
    await tester.pumpAndSettle();
  }

  List<String?> stackOf(TabsRouter tabs, int index) => [
    for (final page in tabs.stackRouterOfIndex(index)!.stack) page.name,
  ];

  // Android only: on web Flutter never tells the platform whether it handles back.
  for (final MapEntry(key: name, value: back) in {
    'system back': systemBack,
    'the predictive back gesture': predictiveBack,
  }.entries) {
    testWidgets('$name in a tab with a pushed page should pop it after a tab switch', (tester) async {
      final tabs = await pumpApp(tester, theme: androidTheme);
      await pushInTab(tester, tabs, 0, 'BookDetailsRoute');
      await showTab(tester, tabs, 1);
      await showTab(tester, tabs, 0);
      expect(frameworkHandlesBack.last, isTrue);

      await back(tester);

      expect(stackOf(tabs, 0), ['BookListRoute']);
      expect(frameworkHandlesBack.last, isFalse);
    }, skip: kIsWeb);
  }

  testWidgets("system back on a tab at its first page should leave the other tab's page", (tester) async {
    final tabs = await pumpApp(tester);
    await pushInTab(tester, tabs, 0, 'BookDetailsRoute');
    await showTab(tester, tabs, 1);

    expect(frameworkHandlesBack.last, isFalse);
    expect(await tester.binding.handlePopRoute(), isFalse);
    await tester.pumpAndSettle();

    expect(stackOf(tabs, 0), ['BookListRoute', 'BookDetailsRoute']);
  }, skip: kIsWeb);

  testWidgets('the predictive back gesture should pop only the page of the tab on screen', (tester) async {
    final tabs = await pumpApp(tester, theme: androidTheme);
    await pushInTab(tester, tabs, 0, 'BookDetailsRoute');
    await showTab(tester, tabs, 1);
    await pushInTab(tester, tabs, 1, 'MyBooksRoute');

    await predictiveBack(tester);

    expect(stackOf(tabs, 1), ['ProfileRoute']);
    expect(stackOf(tabs, 0), ['BookListRoute', 'BookDetailsRoute']);
  });

  testWidgets('the iOS back swipe should pop only the page of the tab on screen', (tester) async {
    final tabs = await pumpApp(tester, theme: iosTheme);
    await pushInTab(tester, tabs, 0, 'BookDetailsRoute');
    await showTab(tester, tabs, 1);
    await pushInTab(tester, tabs, 1, 'MyBooksRoute');

    await swipeBack(tester);

    expect(stackOf(tabs, 1), ['ProfileRoute']);
    expect(stackOf(tabs, 0), ['BookListRoute', 'BookDetailsRoute']);
  });

  testWidgets('system back should pop a page pushed in a tab while it was hidden, once it shows', (tester) async {
    final tabs = await pumpApp(tester);
    await showTab(tester, tabs, 1);
    await pushInTab(tester, tabs, 0, 'BookDetailsRoute');
    await showTab(tester, tabs, 0);

    await systemBack(tester);

    expect(stackOf(tabs, 0), ['BookListRoute']);
  });
}

final _homePage = PageInfo(
  'HomeRoute',
  builder: (_) => const AutoTabsRouter(routes: [_Route('BooksTab'), _Route('ProfileTab')]),
);

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));

class _Route extends PageRouteInfo<void> {
  const _Route(super.name);
}
