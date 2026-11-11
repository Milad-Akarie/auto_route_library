import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/735
// The report has a title and a screenshot, no code. Assumed from the title:
// a bottom navigation bar over AutoTabsRouter whose tabs each hold their own
// nested AutoRouter, and a page in one tab that navigates to a page which
// lives in another tab's stack.
// Steps: tabs are Profile (stack: ProfileRoute) and Settings (stack:
// SettingsRoute, SecurityRoute). On ProfileRoute, call navigateTo
// (SettingsTab(children: [SecurityRoute])).
// A bare navigateTo(SecurityRoute) throws 'no route matches it' by design:
// a route is named with its parents.
// Should: the Settings tab is shown, with SecurityRoute on top.
void main() {
  testWidgets("navigateTo a page in another tab's nested router shows it", (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'MainRoute',
            builder: (_) => AutoTabsRouter(
              routes: const [
                PageRouteInfo('ProfileTab'),
                PageRouteInfo('SettingsTab'),
              ],
              builder: (context, child) => Scaffold(
                body: child,
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: context.tabsRouter.activeIndex,
                  onTap: context.tabsRouter.setActiveIndex,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
          children: [
            AutoRoute(
              path: 'profile',
              page: PageInfo('ProfileTab', builder: (_) => const AutoRouter()),
              children: [
                AutoRoute(
                  path: '',
                  page: PageInfo(
                    'ProfileRoute',
                    builder: (_) => Builder(
                      builder: (context) => TextButton(
                        onPressed: () => unawaited(
                          context.navigateTo(
                            const PageRouteInfo(
                              'SettingsTab',
                              initialChildren: [PageRouteInfo('SecurityRoute')],
                            ),
                          ),
                        ),
                        child: const Text('open security'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AutoRoute(
              path: 'settings',
              page: PageInfo('SettingsTab', builder: (_) => const AutoRouter()),
              children: [
                AutoRoute(
                  path: '',
                  page: PageInfo(
                    'SettingsRoute',
                    builder: (_) => const Text('Settings page'),
                  ),
                ),
                AutoRoute(
                  path: 'security',
                  page: PageInfo(
                    'SecurityRoute',
                    builder: (_) => const Text('Security page'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    expect(find.text('open security'), findsOneWidget);

    await tester.tap(find.text('open security'));
    await tester.pumpAndSettle();
    expect(find.text('Security page'), findsOneWidget);
  });
}
