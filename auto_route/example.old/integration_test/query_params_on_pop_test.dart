import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// Popping a page restores the query params of the page underneath.
// https://github.com/Milad-Akarie/auto_route_library/issues/2085
// https://github.com/Milad-Akarie/auto_route_library/issues/2310
// https://github.com/Milad-Akarie/auto_route_library/issues/2332
// Headless tests: auto_route/test/simple_router/query_params_on_pop_test.dart
// and auto_route/test/web/query_params_on_pop_web_test.dart.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() => router = buildSimpleRouter());

  // Steps: open FirstRoute at '/?search=shoes', push SecondRoute, then pop it.
  // Should: the url, and on web the address bar, is '/?search=shoes' again.
  testWidgets(
    'Popping a page restores the query params of the page underneath',
    (tester) async {
      await pumpRouterApp(tester, router, initialLink: '/?search=shoes');
      expect(router.urlState.url, '/?search=shoes');

      unawaited(router.push(const SecondRoute()));
      await tester.pumpAndSettle();
      expect(router.urlState.url, '/second-route');

      router.pop();
      await tester.pumpAndSettle();
      expectCurrentPage(router, FirstRoute.name);
      expect(router.urlState.url, '/?search=shoes');
      await expectBrowserUrl('/?search=shoes');
    },
  );
}
