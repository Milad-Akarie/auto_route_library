import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'list_query_support/list_router.dart';
import 'support/app.dart';

// A query param of type List<int>, List<double>, List<bool> or a list of an
// enum is read and written as items of that type.
// https://github.com/Milad-Akarie/auto_route_library/issues/2061
// Headless tests: auto_route/test/list_query_param/list_query_param_test.dart
// The router and its page are in list_query_support/list_router.dart, with
// the router generated next to it.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: open the app at the deep link /items?ids=1&ids=2&ids=3.
  // Should: the page shows ids [1, 2, 3], as ints.
  testWidgets('A deep link reads a list of ints', (tester) async {
    await pumpRouterApp(tester, ListRouter(), initialLink: '/items?ids=1&ids=2&ids=3');
    expect(tester.takeException(), isNull);
    expect(find.textContaining('ids [1, 2, 3] '), findsOneWidget);
  });

  // Steps: open /items with lists of doubles, bools and enum names, one of
  // them not a name of the enum.
  // Should: each list holds its own type; the unknown name is left out.
  testWidgets('A deep link reads lists of doubles, bools and enums by name', (tester) async {
    await pumpRouterApp(
      tester,
      ListRouter(),
      initialLink: '/items?prices=1.5&prices=2.5&flags=true&flags=FALSE&sorts=desc&sorts=asc&sorts=nope',
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('prices [1.5, 2.5] flags [true, false] sorts [desc, asc] '), findsOneWidget);
  });

  // Steps: push the items route with lists.
  // Should: the url carries each item, an enum by its name, the form the
  // deep link uses.
  testWidgets('Pushing the route writes the items in the url', (tester) async {
    final router = ListRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push(ItemsRoute(ids: [4, 5], prices: [1.5], flags: [true], sorts: [Sort.desc], picked: [9])));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('ids [4, 5] prices [1.5] flags [true] sorts [desc] picked [9]'), findsOneWidget);
    expect(router.urlState.url, '/items?ids=4&ids=5&prices=1.5&flags=true&sorts=desc&picked=9');
    await expectBrowserUrl('/items?ids=4&ids=5&prices=1.5&flags=true&sorts=desc&picked=9');
  });
}
