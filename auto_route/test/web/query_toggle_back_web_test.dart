@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import '../simple_router/router.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();

  late SimpleRouter router;
  setUp(() async {
    router = SimpleRouter();
    await rewindBrowserHistory();
  });

  // flutter/flutter#108714: on web, after a switch added ?p=true to the url of
  // a pushed page, the browser's back button left the user on that page.
  // Steps: start on FirstRoute, push SecondRoute, navigate to SecondRoute with
  // the query p=true (the switch), press the browser's back button twice.
  // Was: the page stayed at '/second-route?p=true': the router took the
  // browser's entry for the page it showed, since both belong to the same page,
  // and wrote its own url over it as a new entry.
  // Should: back shows '/second-route' without the query, then FirstRoute.
  testWidgets(
    'The browser back button leaves a page whose query params changed',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);

      unawaited(router.push(const SecondRoute()));
      await settleBrowser(tester);
      expect(browserPath, '/second-route');

      unawaited(
        router.navigate(
          const NamedRoute('SecondRoute', queryParams: {'p': 'true'}),
        ),
      );
      await settleBrowser(tester);
      expect(browserPath, '/second-route?p=true');

      await pressBrowserBack(tester);
      expectCurrentPage(router, SecondRoute.name);
      expect(router.currentUrl, '/second-route');
      expect(
        browserPath,
        '/second-route',
        reason: 'after pressBrowserBack(tester)',
      );

      await pressBrowserBack(tester);
      expectCurrentPage(router, FirstRoute.name);
      expect(browserPath, '/');
    },
  );
}
