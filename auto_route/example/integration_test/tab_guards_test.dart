import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// The guards of a tab route are asked before the tab shows.
// https://github.com/Milad-Akarie/auto_route_library/issues/2218
// Headless test: auto_route/test/nested_tabs_router/tab_guards_test.dart
//
// Setup, as in the report and the issues it links (#1041, #1278): the app's
// first page is an AutoTabsRouter with a bottom navigation bar whose onTap is
// setActiveIndex; the profile tab's route has a guard.
// Steps: tap the profile tab, open its url, or swipe to it in a page view or
// tab bar view.
// Reported: the profile tab shows; its guard is never asked.
// Should: the tab shows only once its guard lets it in; a rejected change
// keeps the current tab and its url.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => _signedIn = false);

  testWidgets('tapping a tab whose guard rejects keeps the current tab', (tester) async {
    final router = _buildRouter(_Tabs.indexedStack, _rejectingGuard);
    await pumpRouterApp(tester, router);

    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();

    _expectTab(router, 'FeedRoute');
    await expectBrowserUrl('/feed');
  });

  testWidgets('a guard that redirects to a login page shows the tab after the login', (tester) async {
    final router = _buildRouter(_Tabs.indexedStack, _loginGuard);
    await pumpRouterApp(tester, router);

    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    expectTopPage(router, 'LoginRoute');
    await expectBrowserUrl('/login');

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(router.stack.map((page) => page.routeData.name), ['HomeRoute']);
    _expectTab(router, 'ProfileRoute');
    await expectBrowserUrl('/profile');
  });

  testWidgets('opening the url of a tab whose guard rejects shows the first tab', (tester) async {
    final router = _buildRouter(_Tabs.indexedStack, _rejectingGuard);
    await pumpRouterApp(tester, router, initialLink: '/profile');

    _expectTab(router, 'FeedRoute');
    await expectBrowserUrl('/feed');
  });

  testWidgets('typing the url of a tab whose guard rejects keeps the current tab', (tester) async {
    final router = _buildRouter(_Tabs.indexedStack, _rejectingGuard);
    await pumpRouterAppWithConfig(tester, router);

    typeBrowserUrl('/profile');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    _expectTab(router, 'FeedRoute');
    await expectBrowserUrl('/feed');
  }, skip: !kIsWeb);

  for (final kind in [_Tabs.pageView, _Tabs.tabBar]) {
    testWidgets('swiping to a tab whose guard rejects in a ${kind.name} returns to the current tab', (tester) async {
      final router = _buildRouter(kind, _rejectingGuard);
      await pumpRouterApp(tester, router);

      await tester.fling(find.text('FeedRoute'), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      _expectTab(router, 'FeedRoute');
      await expectBrowserUrl('/feed');
    });

    testWidgets('swiping to a tab whose guard lets it in in a ${kind.name} shows it', (tester) async {
      _signedIn = true;
      final router = _buildRouter(kind, _rejectingGuard);
      await pumpRouterApp(tester, router);

      await tester.fling(find.text('FeedRoute'), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      _expectTab(router, 'ProfileRoute');
      await expectBrowserUrl('/profile');
    });
  }
}

enum _Tabs { indexedStack, pageView, tabBar }

var _signedIn = false;

final _rejectingGuard = AutoRouteGuard.simple((resolver, _) => resolver.next(_signedIn));

final _loginGuard = AutoRouteGuard.simple((resolver, _) {
  if (_signedIn) {
    resolver.next();
  } else {
    resolver.redirectUntil(const NamedRoute('LoginRoute'));
  }
});

RootStackRouter _buildRouter(_Tabs kind, AutoRouteGuard guard) {
  const routes = [NamedRoute('FeedRoute'), NamedRoute('ProfileRoute')];
  Widget bottomBar(TabsRouter tabs) => BottomNavigationBar(
    currentIndex: tabs.activeIndex,
    onTap: tabs.setActiveIndex,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ],
  );
  Widget scaffold(BuildContext context, Widget child) =>
      Scaffold(body: child, bottomNavigationBar: bottomBar(AutoTabsRouter.of(context)));
  final host = switch (kind) {
    _Tabs.indexedStack => AutoTabsRouter(routes: routes, builder: scaffold),
    _Tabs.pageView => AutoTabsRouter.pageView(routes: routes, builder: (context, child, _) => scaffold(context, child)),
    _Tabs.tabBar => AutoTabsRouter.tabBar(routes: routes, builder: (context, child, _) => scaffold(context, child)),
  };
  Widget page(String name) => Center(child: Text(name));
  return RootStackRouter.build(
    routes: [
      AutoRoute(
        page: PageInfo('HomeRoute', builder: (_) => host),
        path: '/',
        children: [
          AutoRoute(
            page: PageInfo('FeedRoute', builder: (_) => page('FeedRoute')),
            path: 'feed',
          ),
          AutoRoute(
            page: PageInfo('ProfileRoute', builder: (_) => page('ProfileRoute')),
            path: 'profile',
            guards: [guard],
          ),
        ],
      ),
      AutoRoute(
        page: PageInfo(
          'LoginRoute',
          builder: (data) => Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  const Text('LoginRoute'),
                  TextButton(
                    onPressed: () {
                      _signedIn = true;
                      data.router.root.reevaluateGuards();
                    },
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
        path: '/login',
      ),
    ],
  );
}

// [name] is the active tab, and the only one on screen.
void _expectTab(RootStackRouter router, String name) {
  final tabs = router.innerRouterOf<TabsRouter>('HomeRoute')!;
  expect(tabs.current.name, name);
  for (final tab in ['FeedRoute', 'ProfileRoute']) {
    expect(find.text(tab), tab == name ? findsOneWidget : findsNothing, reason: tab);
  }
}
