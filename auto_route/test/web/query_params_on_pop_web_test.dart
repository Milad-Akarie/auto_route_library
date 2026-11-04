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

  // https://github.com/Milad-Akarie/auto_route_library/issues/2085
  // https://github.com/Milad-Akarie/auto_route_library/issues/2310
  // https://github.com/Milad-Akarie/auto_route_library/issues/2332
  // Open FirstRoute with query params, push SecondRoute, then pop it.
  // The browser should step back to FirstRoute's own entry, query params and all,
  // so a refresh reopens the same page.
  testWidgets('Popping on web steps back to the entry with the query params', (tester) async {
    await pumpRouterConfigApp(tester, router.config(deepLinkBuilder: (_) => const DeepLink.path('/?search=shoes')));
    await settleBrowser(tester);
    final start = browserSerialCount;
    expect(browserPath, '/?search=shoes');

    unawaited(router.push(const SecondRoute()));
    await settleBrowser(tester);
    expect(browserPath, '/second-route');

    router.pop();
    await settleBrowser(tester);
    expectCurrentPage(router, FirstRoute.name);
    expect(browserPath, '/?search=shoes');
    expect(browserSerialCount, start);
  });
}
