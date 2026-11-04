import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// With includePrefixMatches, swiping back after a reload animates a Hero.
// https://github.com/Milad-Akarie/auto_route_library/issues/1670
// Headless test: auto_route/test/web/reload_hero_web_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: open the app on '/second' with includePrefixMatches, as a reload
  // does on web, so the stack is rebuilt as [Page1, Page2]; then swipe back
  // from the left edge. Both pages hold a Hero with transitionOnUserGestures.
  // Should: Page1 shows, with no error.
  testWidgets('With includePrefixMatches, swiping back from a deep link animates a Hero without an error', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      defaultRouteType: const RouteType.cupertino(),
      routes: [
        AutoRoute(page: _page1, path: '/'),
        AutoRoute(page: _page2, path: '/second'),
      ],
    );
    await pumpRouterConfigApp(
      tester,
      router.config(
        includePrefixMatches: true,
        deepLinkBuilder: (link) => link.initial ? const DeepLink.path('/second') : link,
      ),
    );
    expect(router.stack.map((p) => p.name), ['Page1Route', 'Page2Route']);
    expect(find.text('Page 2'), findsOneWidget);

    await swipeBack(tester);
    expect(tester.takeException(), isNull);
    expect(router.stack.map((p) => p.name), ['Page1Route']);
    expect(find.text('Page 1'), findsOneWidget);
    await expectBrowserUrl('/');
  });
}

final PageInfo _page1 = _heroPage('Page1Route', 'Page 1');
final PageInfo _page2 = _heroPage('Page2Route', 'Page 2');

PageInfo _heroPage(String name, String label) => PageInfo(
  name,
  builder: (_) => Scaffold(
    body: Center(
      child: Hero(tag: #tag, transitionOnUserGestures: true, child: Text(label)),
    ),
  ),
);
