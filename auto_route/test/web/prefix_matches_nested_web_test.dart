@TestOn('browser')
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' show window;

import '../main_router.dart';
import '../nested_tabs_router/router.dart';
import '../router_test_utils.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();
  setUp(rewindBrowserHistory);

  // https://github.com/Milad-Akarie/auto_route_library/issues/2067
  // With includePrefixMatches, the AutoTabsRouter ignored a url typed in the
  // address bar and the browser's back and forward buttons.
  // Steps: navigate to the second tab, then the third, press the browser's back
  // button, then its forward button, then type the second tab's nested page's
  // url, then '/'.
  // Should: each step shows the tab and page its url names.
  testWidgets('With includePrefixMatches on web, tabs follow the browser buttons and typed urls', (tester) async {
    final router = NestedTabsRouter();
    await pumpRouterConfigApp(tester, router.config(includePrefixMatches: true));
    await settleBrowser(tester);
    unawaited(router.navigate(const Tab2Route()));
    await settleBrowser(tester);
    unawaited(router.navigate(const Tab3Route()));
    await settleBrowser(tester);
    expect(browserPath, '/tab3');

    await pressBrowserBack(tester);
    expect(browserPath, '/tab2');
    expect(find.text(Tab2Nested1Route.name), findsOneWidget);

    await browserMove(tester, () => window.history.forward());
    expect(browserPath, '/tab3');
    expect(find.text(Tab3Nested1Route.name), findsOneWidget);

    await browserMove(tester, () => window.location.hash = '/tab2/tab2Nested2');
    expect(find.text(Tab2Nested2Route.name), findsOneWidget);
    expectTopPage(router, Tab2Nested2Route.name);

    await browserMove(tester, () => window.location.hash = '/');
    expect(find.text(Tab1Route.name), findsOneWidget);
  });
}
