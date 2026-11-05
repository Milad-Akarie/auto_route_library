import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import 'router.dart';

void main() {
  late SimpleRouter router;
  setUp(() => router = SimpleRouter());

  // https://github.com/Milad-Akarie/auto_route_library/issues/2085
  // https://github.com/Milad-Akarie/auto_route_library/issues/2310
  // https://github.com/Milad-Akarie/auto_route_library/issues/2332
  // Open FirstRoute with query params, push SecondRoute, then pop it.
  // The url should get FirstRoute's query params back, not lose them.
  testWidgets('Popping a page restores the query params of the page underneath', (tester) async {
    await pumpRouterApp(tester, router, initialLink: '/?search=shoes');
    expect(router.urlState.url, '/?search=shoes');

    unawaited(router.push(const SecondRoute()));
    await tester.pumpAndSettle();
    expect(router.urlState.url, '/second-route');

    router.pop();
    await tester.pumpAndSettle();
    expectCurrentPage(router, FirstRoute.name);
    expect(router.urlState.url, '/?search=shoes', reason: 'after router.pop()');
    expect(router.current.queryParams.rawMap, {'search': 'shoes'});
  });

  testWidgets('Popping a page with its own query params restores those of the page underneath', (tester) async {
    await pumpRouterApp(tester, router, initialLink: '/?search=shoes#top');
    unawaited(router.pushPath('/second-route?page=2'));
    await tester.pumpAndSettle();
    expect(router.urlState.url, '/second-route?page=2');

    router.pop();
    await tester.pumpAndSettle();
    expect(router.urlState.url, '/?search=shoes#top');
  });

  testWidgets('Removing the top page restores the query params of the page underneath', (tester) async {
    await pumpRouterApp(tester, router, initialLink: '/?search=shoes');
    unawaited(router.pushPath('/second-route?page=2'));
    await tester.pumpAndSettle();

    router.removeLast();
    await tester.pumpAndSettle();
    expect(router.urlState.url, '/?search=shoes');
  });
}
