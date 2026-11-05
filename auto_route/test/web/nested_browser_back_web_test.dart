@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import '../main_router.dart';
import '../nested_router/router.dart';
import '../nested_tabs_router/router.dart';
import '../router_test_utils.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();
  setUp(rewindBrowserHistory);

  // https://github.com/Milad-Akarie/auto_route_library/issues/1891
  // https://github.com/Milad-Akarie/auto_route_library/issues/1972
  // In nested routers, the browser's back button changed the url but left the
  // screen as it was. Each test pushes inside a nested router, then presses
  // back.
  testWidgets(
    'The browser back button on web pops a page pushed in a nested router',
    (tester) async {
      final router = NestedRouter();
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);
      unawaited(router.navigate(SecondHostRoute()));
      await settleBrowser(tester);
      unawaited(
        router
            .innerRouterOf<StackRouter>(SecondHostRoute.name)!
            .push(const SecondNested2Route()),
      );
      await settleBrowser(tester);
      expectTopPage(router, SecondNested2Route.name);

      await pressBrowserBack(tester);
      expect(browserPath, '/second');
      expectTopPage(router, SecondNested1Route.name);

      await pressBrowserBack(tester);
      expect(browserPath, '/');
      expectCurrentPage(router, FirstRoute.name);
    },
  );

  testWidgets(
    'The browser back button on web goes back through tabs and their stacks',
    (tester) async {
      final router = NestedTabsRouter();
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);
      unawaited(router.navigate(const Tab2Route()));
      await settleBrowser(tester);
      unawaited(
        router
            .innerRouterOf<TabsRouter>(TabsHostRoute.name)!
            .stackRouterOfIndex(1)!
            .push(const Tab2Nested2Route()),
      );
      await settleBrowser(tester);
      unawaited(router.navigate(const Tab3Route()));
      await settleBrowser(tester);
      expect(browserPath, '/tab3');

      await pressBrowserBack(tester);
      expect(browserPath, '/tab2/tab2Nested2');
      expect(find.text(Tab2Nested2Route.name), findsOneWidget);

      await pressBrowserBack(tester);
      expect(browserPath, '/tab2');
      expect(find.text(Tab2Nested1Route.name), findsOneWidget);

      await pressBrowserBack(tester);
      expect(browserPath, '/');
      expect(find.text(Tab1Route.name), findsOneWidget);
    },
  );
}
