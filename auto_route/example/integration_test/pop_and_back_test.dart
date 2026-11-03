import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// Pop then back doesn't return to the popped page.
// https://github.com/Milad-Akarie/auto_route_library/issues/1839
// Headless test: auto_route/test/simple_router/pop_and_back_test.dart
//
// Skipped on web: the web half of #1839 is still open. On web, back() walks
// the browser's own history, which still holds the popped page.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() => router = buildSimpleRouter());

  // Steps: start on FirstRoute, navigate to SecondRoute, then to ThirdRoute,
  // pop ThirdRoute, then call back() from SecondRoute.
  // Should: back() lands on FirstRoute, not on the ThirdRoute just popped.
  testWidgets('Popping then going back does not return to the popped page', (tester) async {
    await pumpRouterApp(tester, router);
    expectCurrentPage(router, FirstRoute.name);
    expect(router.urlState.url, '/');

    unawaited(router.navigate(const SecondRoute()));
    await tester.pumpAndSettle();
    expectCurrentPage(router, SecondRoute.name);
    expect(router.navigationHistory.length, 2);

    unawaited(router.navigate(const ThirdRoute()));
    await tester.pumpAndSettle();
    expectCurrentPage(router, ThirdRoute.name);
    expect(router.navigationHistory.length, 3);

    router.pop();
    await tester.pumpAndSettle();
    expectCurrentPage(router, SecondRoute.name);
    expect(router.navigationHistory.length, 2);
    expect(router.urlState.url, '/second-route');

    router.back();
    await tester.pumpAndSettle();
    expectCurrentPage(router, FirstRoute.name);
    expect(router.stack.map((p) => p.name), [FirstRoute.name]);
    expect(router.navigationHistory.length, 1);
    expect(router.urlState.url, '/');
    expect(router.canNavigateBack, isFalse);
  }, skip: kIsWeb);

  // Steps: pushAll SecondRoute and ThirdRoute (only the last one gets a
  // history entry), pop ThirdRoute, then call back().
  // Should: back() lands on FirstRoute.
  testWidgets('Popping a page pushed with pushAll then going back does not return to it', (tester) async {
    await pumpRouterApp(tester, router);
    unawaited(router.pushAll([const SecondRoute(), const ThirdRoute()]));
    await tester.pumpAndSettle();
    expectCurrentPage(router, ThirdRoute.name);
    expect(router.navigationHistory.length, 2);

    router.pop();
    await tester.pumpAndSettle();
    expectCurrentPage(router, SecondRoute.name);
    expect(router.navigationHistory.length, 2);
    expect(router.urlState.url, '/second-route');

    router.back();
    await tester.pumpAndSettle();
    expectCurrentPage(router, FirstRoute.name);
    expect(router.stack.map((p) => p.name), [FirstRoute.name]);
    expect(router.navigationHistory.length, 1);
  }, skip: kIsWeb);
}
