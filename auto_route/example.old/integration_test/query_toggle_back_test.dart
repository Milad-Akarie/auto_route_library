import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// flutter/flutter#108714: on web, after a switch added ?p=true to the url of
// a pushed page, the browser's back button left the user on that page.
// Headless tests: auto_route/test/web/query_toggle_back_web_test.dart.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() => router = buildSimpleRouter());

  // Steps: push SecondRoute, navigate to SecondRoute with the query p=true,
  // then go back.
  // Should: on web, the browser's back button shows '/second-route' without the
  // query, then FirstRoute at '/'. Elsewhere, back leaves SecondRoute at once.
  testWidgets('Back leaves a page whose query params changed', (tester) async {
    await pumpRouterAppWithConfig(tester, router);
    unawaited(router.push(const SecondRoute()));
    await tester.pumpAndSettle();
    unawaited(router.navigate(const NamedRoute('SecondRoute', queryParams: {'p': 'true'})));
    await tester.pumpAndSettle();
    expect(router.currentUrl, '/second-route?p=true');
    await expectBrowserUrl('/second-route?p=true');

    if (kIsWeb) {
      final entry = browserEntryIndex()!;
      pressBrowserBack();
      await expectBrowserEntry(entry - 1);
      await tester.pumpAndSettle();
      expectCurrentPage(router, SecondRoute.name);
      expect(router.currentUrl, '/second-route');
      await expectBrowserUrl('/second-route');
      pressBrowserBack();
      await expectBrowserEntry(entry - 2);
      await tester.pumpAndSettle();
    } else {
      await systemBack(tester);
    }
    expect(tester.takeException(), isNull);
    expectCurrentPage(router, FirstRoute.name);
    await expectBrowserUrl('/');
  });
}
