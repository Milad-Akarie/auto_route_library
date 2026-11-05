// The old parameter names are tested on purpose: they must keep working until they are removed.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart' show SizedBox, ValueKey;
import 'package:flutter_test/flutter_test.dart';

// copyWith takes each field's own name: rawPathParams, rawQueryParams and
// initialChildren on PageRouteInfo, params and id on RouteMatch. The old
// names (params, queryParams, children, pathParams) still work, deprecated,
// and lose to the new ones when both are passed.
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

  test('PageRouteInfo.copyWith still takes the old names, and the new ones win', () {
    final copy = route.copyWith(
      params: {'id': 3},
      queryParams: {'tab': 'notes'},
      children: const [PageRouteInfo('ChapterRoute')],
    );
    expect(copy.rawPathParams, {'id': 3});
    expect(copy.rawQueryParams, {'tab': 'notes'});
    expect(copy.initialChildren, const [PageRouteInfo('ChapterRoute')]);
    expect(route.copyWith(params: {'id': 3}, rawPathParams: {'id': 4}).rawPathParams, {'id': 4});
  });

  test('RouteMatch.copyWith sets params and id, and still takes pathParams', () {
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
    expect(match.copyWith(params: const Parameters({'id': 2})).params, const Parameters({'id': 2}));
    expect(match.copyWith(pathParams: const Parameters({'id': 3})).params, const Parameters({'id': 3}));
    expect(match.copyWith(id: const ValueKey('other')).id, const ValueKey('other'));
    expect(match.copyWith().id, match.id);
  });
}
