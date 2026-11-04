import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

PageInfo _page(String name) => .new(name, builder: (_) => Text(name));

// https://github.com/Milad-Akarie/auto_route_library/issues/1078 and #1184
// Steps: open the app from a link while it isn't running, with a link to a
// page under a parent, to a page behind a guard, and to a top-level page.
// Reported: the app shows the link's page for two seconds and returns to the
// initial route, or never shows it (iOS).
// Should: the page of the link shows and stays, on top of the initial page.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      guards: [AutoRouteGuard.simple((resolver, _) => resolver.next())],
      routes: [
        AutoRoute(path: '/', page: _page('HomeRoute')),
        AutoRoute(path: '/book/:id', page: _page('BookRoute')),
        AutoRoute(
          path: '/account',
          page: PageInfo('AccountRoute', builder: (_) => const AutoRouter()),
          children: [
            AutoRoute(path: '', page: _page('OverviewRoute')),
            AutoRoute(path: 'settings', page: _page('SettingsRoute')),
          ],
        ),
      ],
    );
  });

  final links = {'/book/1': 'BookRoute', '/account/settings': 'SettingsRoute', '/account': 'OverviewRoute'};
  for (final MapEntry(key: link, value: page) in links.entries) {
    testWidgets('a cold start link to $link shows $page and stays', (tester) async {
      await pumpRouterApp(tester, router, initialLink: link);
      expect(find.text(page), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text(page), findsOneWidget);
      expect(find.text('HomeRoute'), findsNothing);
      expect(router.currentUrl, link);
    });
  }
}
