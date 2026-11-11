import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart' show SizedBox, ValueKey;
import 'package:flutter_test/flutter_test.dart';

// copyWith takes each field's own name: rawPathParams, rawQueryParams and
// initialChildren on PageRouteInfo, params and id on RouteMatch.
void main() {
  const route = PageRouteInfo('BookRoute', rawPathParams: {'id': 1});

  test('PageRouteInfo.copyWith sets each field by its own name', () {
    final copy = route.copyWith(
      rawPathParams: {'id': 2},
      rawQueryParams: {'tab': 'reviews'},
      initialChildren: const [PageRouteInfo('ChapterRoute')],
      stringMatch: '/books/2',
      redirectedFrom: '/old-books/2',
      argsEquality: false,
    );
    expect(copy.rawPathParams, {'id': 2});
    expect(copy.rawQueryParams, {'tab': 'reviews'});
    expect(copy.initialChildren, const [PageRouteInfo('ChapterRoute')]);
    expect(copy.stringMatch, '/books/2');
    expect(copy.redirectedFrom, '/old-books/2');
    expect(copy.argsEquality, isFalse);
  });

  test('RouteMatch.copyWith sets params and id', () {
    final match = RouteMatch<Object?>(
      config: AutoRoute(
        page: PageInfo('BookRoute', builder: (_) => const SizedBox()),
        path: '/books/:id',
      ),
      segments: const ['books', '1'],
      stringMatch: '/books/1',
      key: const ValueKey('BookRoute'),
      params: const Parameters({'id': 1}),
    );
    expect(
      match.copyWith(params: const Parameters({'id': 2})).params,
      const Parameters({'id': 2}),
    );
    expect(
      match.copyWith(id: const ValueKey('other')).id,
      const ValueKey('other'),
    );
    expect(match.copyWith().id, match.id);
  });
}
