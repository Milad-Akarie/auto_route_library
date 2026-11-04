import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Found by DCM's avoid-incomplete-copy-with while moving the package to
// very_good_analysis; no upstream issue.
// Steps: push a route with a child and a fragment:
// `NamedRoute('BooksRoute', children: [NamedRoute('BookListRoute')], fragment: 'top')`.
// Happens: the url is /books, without #top. The matcher hands the parent's
// fragment to the child with `childRoute.copyWith(fragment: ...)`, the url
// takes its fragment from the last segment, and PageRouteInfo.copyWith left
// the fragment out of the copy.
// Should: the url is /books#top, as it is for a route without children.
void main() {
  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(
        path: '/',
        page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
      ),
      AutoRoute(
        path: '/books',
        page: PageInfo('BooksRoute', builder: (_) => const AutoRouter()),
        children: [
          AutoRoute(
            path: '',
            page: PageInfo('BookListRoute', builder: (_) => const Text('BookListRoute')),
          ),
        ],
      ),
    ],
  );

  testWidgets('A pushed route with children keeps its fragment in the url', (tester) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router);
    // Completes when the page is popped, so the test does not wait for it.
    unawaited(router.push(const NamedRoute('BooksRoute', children: [NamedRoute('BookListRoute')], fragment: 'top')));
    await tester.pumpAndSettle();
    expect(find.text('BookListRoute'), findsOneWidget);
    expect(router.urlState.url, '/books#top');
  });

  test('PageRouteInfo.copyWith keeps every field it does not override', () {
    const route = PageRouteInfo<String>(
      'BookRoute',
      args: 'args',
      rawPathParams: {'id': '1'},
      rawQueryParams: {'tab': 'reviews'},
      fragment: 'top',
      stringMatch: '/books/1',
      redirectedFrom: '/old-books/1',
      argsEquality: false,
    );
    final copy = route.copyWith(name: 'OtherBookRoute');
    expect(copy.routeName, 'OtherBookRoute');
    expect(copy.args, 'args');
    expect(copy.rawPathParams, {'id': '1'});
    expect(copy.rawQueryParams, {'tab': 'reviews'});
    expect(copy.fragment, 'top');
    expect(copy.stringMatch, '/books/1');
    expect(copy.redirectedFrom, '/old-books/1');
    expect(copy.argsEquality, isFalse);
    expect(route.copyWith(fragment: 'end').fragment, 'end');
  });
}
