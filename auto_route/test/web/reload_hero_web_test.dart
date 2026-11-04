@TestOn('browser')
library;

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();
  setUp(rewindBrowserHistory);

  // https://github.com/Milad-Akarie/auto_route_library/issues/1670
  // With includePrefixMatches, a reload on '/second' rebuilds the stack as
  // [Page1, Page2]. Swiping back then threw "box.hasSize && box.size.isFinite
  // is not true" from a Hero with transitionOnUserGestures, because Page1 had
  // never been laid out.
  // Steps, as in the reporter's app on a Mac: open the app on '/second', as a
  // reload does, then swipe back from the left edge.
  // Should: Page1 shows, with no error.
  testWidgets('With includePrefixMatches on web, swiping back after a reload animates a Hero without an error', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page1, path: '/'),
        AutoRoute(page: _page2, path: '/second'),
      ],
    );
    router.routeInfoProvider(initialRouteInformation: RouteInformation(uri: Uri.parse('/second')));
    await pumpRouterConfigApp(tester, router.config(includePrefixMatches: true));
    await settleBrowser(tester);
    expect(router.stack.map((p) => p.name), ['Page1Route', 'Page2Route']);
    expect(find.text('Page 2'), findsOneWidget);

    await tester.dragFrom(const Offset(2, 300), const Offset(500, 0));
    await settleBrowser(tester);
    expect(tester.takeException(), isNull);
    expect(router.stack.map((p) => p.name), ['Page1Route']);
    expect(find.text('Page 1'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}

final _page1 = _heroPage('Page1Route', 'Page 1');
final _page2 = _heroPage('Page2Route', 'Page 2');

PageInfo _heroPage(String name, String label) => PageInfo(
  name,
  builder: (_) => Scaffold(
    body: Center(
      child: Hero(tag: #tag, transitionOnUserGestures: true, child: Text(label)),
    ),
  ),
);
