@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();

  late RootStackRouter router;
  setUp(() async {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('ARoute'), path: '/'),
        AutoRoute(page: _page('BRoute'), path: '/b'),
      ],
    );
    await rewindBrowserHistory();
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1044
  // On web, open B over A, then in one callback call
  // popUntilRouteWithName('ARoute') and push(ARoute()).
  // Reported: this did not work as pushAndPopUntil does. On web it also made
  // Flutter's Router assert: "Both Router.navigate and Router.neglect have
  // been called in this build cycle", since the pop and the push each told it
  // how to report the url.
  // Should: no exception, A on top of A, and the address '/'.
  testWidgets(
    'On web, popUntilRouteWithName then push in one frame throws nothing',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);
      unawaited(router.push(const _Route('BRoute')));
      await settleBrowser(tester);
      expect(browserPath, '/b');

      router.popUntilRouteWithName('ARoute');
      unawaited(router.push(const _Route('ARoute')));
      await settleBrowser(tester);
      expect(tester.takeException(), isNull);
      expect(router.stack.map((m) => m.name), ['ARoute', 'ARoute']);
      expect(browserPath, '/');
    },
  );
}

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}

PageInfo _page(String name) => .new(name, builder: (_) => Text(name));
