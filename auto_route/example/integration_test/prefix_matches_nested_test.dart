import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// With includePrefixMatches, tabs follow the browser's buttons and typed urls.
// https://github.com/Milad-Akarie/auto_route_library/issues/2067
// Headless test: auto_route/test/web/prefix_matches_nested_web_test.dart
//
// Runs only on web, the one platform with browser buttons and an address bar.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: navigate to the second tab, press the browser's back button, then
  // its forward button, then type the second tab's nested page's url, then '/'.
  // Should: each step shows the tab and page its url names.
  testWidgets('With includePrefixMatches, tabs follow the browser buttons and typed urls', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: TabsHostRoute.page,
          children: [
            AutoRoute(path: '', page: Tab1Route.page),
            AutoRoute(
              path: 'tab2',
              page: Tab2Route.page,
              children: [
                AutoRoute(path: '', page: Tab2Nested1Route.page),
                AutoRoute(path: 'tab2Nested2', page: Tab2Nested2Route.page),
              ],
            ),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(
      tester,
      router.config(
        includePrefixMatches: true,
        deepLinkBuilder: (link) => link.initial ? DeepLink.path('/') : link,
      ),
    );
    unawaited(router.navigate(const Tab2Route()));
    await tester.pumpAndSettle();
    await expectBrowserUrl('/tab2');
    expect(find.text(Tab2Nested1Route.name), findsOneWidget);

    pressBrowserBack();
    await expectBrowserUrl('/');
    await tester.pumpAndSettle();
    expect(find.text(Tab1Route.name), findsOneWidget);

    pressBrowserForward();
    await expectBrowserUrl('/tab2');
    await tester.pumpAndSettle();
    expect(find.text(Tab2Nested1Route.name), findsOneWidget);

    typeBrowserUrl('/tab2/tab2Nested2');
    await expectBrowserUrl('/tab2/tab2Nested2');
    await tester.pumpAndSettle();
    expectTopPage(router, Tab2Nested2Route.name);

    typeBrowserUrl('/');
    await expectBrowserUrl('/');
    await tester.pumpAndSettle();
    expect(find.text(Tab1Route.name), findsOneWidget);
  }, skip: !kIsWeb);
}
