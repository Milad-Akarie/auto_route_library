import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'list_query_support/list_router.dart';
import 'support/app.dart';

// flutter/flutter#108437: a query param typed as a Set or an Iterable is read
// from a link as its own type, where it threw a TypeError.
// Headless tests: auto_route/test/list_query_param/list_query_param_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: open the app at /tags with tags, ids and sorts repeated.
  // Should: tags is a Set holding a repeated tag once, ids the ints, sorts
  // the enum values.
  testWidgets('a deep link reads a Set and an Iterable', (tester) async {
    await pumpRouterApp(tester, ListRouter(), initialLink: '/tags?tags=a&tags=b&tags=a&ids=1&ids=2&sorts=desc');
    expect(tester.takeException(), isNull);
    expect(find.text('tags {a, b} ids [1, 2] sorts [desc]'), findsOneWidget);
  });

  // Steps: push the tags route with a Set, an Iterable and a Set of an enum.
  // Should: the url, in the router and the browser, carries each item.
  testWidgets('pushing a Set and an Iterable writes their items in the url', (tester) async {
    final router = ListRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push(TagsRoute(tags: const {'x'}, ids: const [3], sorts: const {.asc})));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('tags {x} ids [3] sorts [asc]'), findsOneWidget);
    expect(router.urlState.url, '/tags?tags=x&ids=3&sorts=asc');
    await expectBrowserUrl('/tags?tags=x&ids=3&sorts=asc');
  });
}
