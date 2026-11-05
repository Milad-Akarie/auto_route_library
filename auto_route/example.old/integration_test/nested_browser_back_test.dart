import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// The browser's back button pops a page pushed in a nested router.
// https://github.com/Milad-Akarie/auto_route_library/issues/1891
// https://github.com/Milad-Akarie/auto_route_library/issues/1972
// Headless test: auto_route/test/web/nested_browser_back_web_test.dart
//
// Runs only on web, the one platform with a browser back button.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('nested browser back', () {
    // Steps: navigate to SecondHostRoute, push SecondNested3Route in its nested
    // router, then press the browser's back button.
    // Should: the url and the screen both go back to SecondNested1Route.
    testWidgets(
      'The browser back button pops a page pushed in a nested router',
      (tester) async {
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(path: '/', page: FirstRoute.page),
            AutoRoute(
              path: '/second',
              page: SecondHostRoute.page,
              children: [
                AutoRoute(path: '', page: SecondNested1Route.page),
                AutoRoute(path: 'nested3', page: SecondNested3Route.page),
              ],
            ),
          ],
        );
        await pumpRouterAppWithConfig(tester, router);
        unawaited(router.navigate(const SecondHostRoute()));
        await tester.pumpAndSettle();
        unawaited(
          router
              .innerRouterOf<StackRouter>(SecondHostRoute.name)!
              .push(const SecondNested3Route()),
        );
        await tester.pumpAndSettle();
        await expectBrowserUrl('/second/nested3');

        pressBrowserBack();
        await expectBrowserUrl('/second');
        await tester.pumpAndSettle();
        expectTopPage(router, SecondNested1Route.name);
      },
      skip: !kIsWeb,
    );
  });
}
