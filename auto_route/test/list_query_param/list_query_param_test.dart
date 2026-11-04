import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../router_test_utils.dart';
import 'list_router.dart';

// A query param of type List<int>, List<double>, List<bool> or a list of an
// enum is read and written as items of that type.
// https://github.com/Milad-Akarie/auto_route_library/issues/2061
// Steps: open /items?ids=1&ids=2&ids=3, a page whose constructor takes
// @QueryParam() List<int>? ids. The router and its page are in
// list_router.dart, with the router generated next to it; its page didn't
// compile before, the generator wrote `queryParams.optList('ids')`, a
// List<String>?.
// Should: the page shows ids [1, 2, 3].
void main() {
  Future<void> openItems(WidgetTester tester, String link) async {
    await pumpRouterApp(tester, ListRouter(), initialLink: link);
    expect(tester.takeException(), isNull);
  }

  testWidgets('a deep link reads a list of ints', (tester) async {
    await openItems(tester, '/items?ids=1&ids=2&ids=3');
    expect(find.textContaining('ids [1, 2, 3] '), findsOneWidget);
  });

  testWidgets('a deep link with one value reads a list of one', (tester) async {
    await openItems(tester, '/items?ids=7');
    expect(find.textContaining('ids [7] '), findsOneWidget);
  });

  testWidgets('an item that is not an int is left out', (tester) async {
    await openItems(tester, '/items?ids=1&ids=x&ids=3');
    expect(find.textContaining('ids [1, 3] '), findsOneWidget);
  });

  testWidgets('a deep link reads lists of doubles, bools and enums by name', (tester) async {
    await openItems(tester, '/items?prices=1.5&prices=2.5&flags=true&flags=FALSE&sorts=desc&sorts=asc&sorts=nope');
    expect(find.textContaining('prices [1.5, 2.5] flags [true, false] sorts [desc, asc] '), findsOneWidget);
  });

  testWidgets('a list that is not in the url is null, or the default', (tester) async {
    await openItems(tester, '/items');
    expect(find.text('ids null prices null flags null sorts null picked [1, 2]'), findsOneWidget);
  });

  // Pushing the route puts the items in the url the way the deep link has
  // them, an enum by its name.
  testWidgets('pushing the route writes the items in the url', (tester) async {
    final router = ListRouter();
    await pumpRouterApp(tester, router);
    unawaited(
      router.push(
        ItemsRoute(
          ids: const [4, 5],
          prices: const [1.5],
          flags: const [true],
          sorts: const [.desc],
          picked: const [9],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('ids [4, 5] prices [1.5] flags [true] sorts [desc] picked [9]'), findsOneWidget);
    expect(router.urlState.url, '/items?ids=4&ids=5&prices=1.5&flags=true&sorts=desc&picked=9');
  });
}
