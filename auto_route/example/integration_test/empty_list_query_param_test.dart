import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'list_query_support/list_router.dart';
import 'support/app.dart';

// flutter/flutter#127373: a route whose list query params are all empty
// leaves no stray '?' at the end of its url.
// Headless test: auto_route/test/list_query_param/list_query_param_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: push the items route with ids and picked both empty lists.
  // Should: the page shows the empty lists, and the url, in the router and
  // the browser, is '/items' with no '?'.
  testWidgets('an empty list query param leaves no ? in the url', (tester) async {
    final router = ListRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push(ItemsRoute(ids: const [], picked: const [])));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('ids [] prices null flags null sorts null picked []'), findsOneWidget);
    expect(router.urlState.url, '/items');
    await expectBrowserUrl('/items');
  });
}
