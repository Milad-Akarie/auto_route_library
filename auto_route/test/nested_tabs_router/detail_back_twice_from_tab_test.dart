import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../named_page.dart';
import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1404
  // Reported: opening a detail page from a tab and going back worked once, the second time back ended on '/home' with an empty page.
  // Steps: guarded HomeRoute '/home' (maintainState) hosts LibraryRoute, whose tabs are Tab1Route and Tab2Route, both reached through
  // RedirectRoutes, and a guarded root route '/home/library/:libraryType/meetings/:meetingId' with usesPathAsKey.
  // From Tab1Route navigate to the detail page and back() three times.
  // Should: each back shows Tab1Route at '/home/library/tab1'.
  testWidgets('Going back from a detail page opened from a tab returns to the tab every time', (tester) async {
    void pass(NavigationResolver resolver, StackRouter _) => resolver.next();
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(name: 'LoginRoute', path: '/', builder: (_, _) => const NamedPage('LoginRoute')),
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/home',
          guards: [AutoRouteGuard.simple(pass), AutoRouteGuard.simple(pass), AutoRouteGuard.simple(pass)],
          builder: (_, _) => const Scaffold(
            body: Column(
              children: [
                Text('header'),
                Expanded(child: AutoRouter()),
              ],
            ),
          ),
          children: [
            RedirectRoute(path: '', redirectTo: 'library'),
            NamedRouteDef(
              name: 'LibraryRoute',
              path: 'library',
              builder: (_, _) => AutoTabsRouter(
                routes: const [NamedRoute('Tab1Route'), NamedRoute('Tab2Route')],
                builder: (_, child) => child,
              ),
              children: [
                RedirectRoute(path: '', redirectTo: 'tab1'),
                NamedRouteDef(name: 'Tab1Route', path: 'tab1', builder: (_, _) => const NamedPage('Tab1Route')),
                NamedRouteDef(name: 'Tab2Route', path: 'tab2', builder: (_, _) => const NamedPage('Tab2Route')),
              ],
            ),
          ],
        ),
        NamedRouteDef(
          name: 'MeetingDetailRoute',
          path: '/home/library/:libraryType/meetings/:meetingId',
          usesPathAsKey: true,
          guards: [AutoRouteGuard.simple(pass)],
          builder: (_, data) => NamedPage('meeting ${data.params.getString('meetingId')}'),
        ),
      ],
    );
    await pumpRouterApp(tester, router, initialLink: '/home');
    expect(router.urlState.url, '/home/library/tab1');

    for (var round = 0; round < 3; round++) {
      final tab = tester.element(find.text('Tab1Route'));
      unawaited(
        tab.router.navigate(const NamedRoute('MeetingDetailRoute', params: {'libraryType': 'own', 'meetingId': '1'})),
      );
      await tester.pumpAndSettle();
      expect(find.text('meeting 1'), findsOneWidget, reason: 'round $round');

      tester.element(find.text('meeting 1')).back();
      await tester.pumpAndSettle();
      expect(find.text('Tab1Route'), findsOneWidget, reason: 'round $round');
      expect(router.urlState.url, '/home/library/tab1', reason: 'round $round');
    }
  }, skip: kIsWeb); // back() on web moves the browser's history, which this runner keeps in memory.
}
