import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Found by strict-casts while moving the package to very_good_analysis; no
// upstream issue.
// Steps: a page reads a query param with `queryParams.optString('tag')`, and a
// deep link repeats the key: `/products?tag=red&tag=blue`. The router keeps a
// repeated key as a list, so the page gets `['red', 'blue']`.
// Happens: optString and getString cast the list to String and throw a
// TypeError, so the page fails to build. A value pushed as a number
// (`queryParams: {'page': 2}`) throws the same way.
// Should: they return the last value, as Uri.queryParameters does, and a
// number as its text, as optInt and the other getters already read any value.
void main() {
  test('optString and getString return the last value of a repeated key', () {
    const params = Parameters({
      'tag': ['red', 'blue'],
    });
    expect(params.optString('tag'), 'blue');
    expect(params.getString('tag'), 'blue');
  });

  test('optString and getString return a number as its text', () {
    const params = Parameters({'page': 2});
    expect(params.optString('page'), '2');
    expect(params.getString('page'), '2');
  });

  test('optString and getString keep the default for a missing or empty key', () {
    const params = Parameters({'tag': <String>[]});
    expect(params.optString('missing', 'none'), 'none');
    expect(params.optString('tag', 'none'), 'none');
    expect(() => params.getString('tag'), throwsFlutterError);
  });

  testWidgets('A page reading optString builds from a deep link that repeats the key', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
        ),
        AutoRoute(
          path: '/products',
          page: PageInfo(
            'ProductsRoute',
            builder: (data) => Scaffold(body: Text('Tag ${data.queryParams.optString('tag') ?? 'null'}')),
          ),
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    // Completes when the page is popped, so the test does not wait for it.
    unawaited(router.navigatePath('/products?tag=red&tag=blue'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Tag blue'), findsOneWidget);
  });
}
