import 'dart:collection';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/matcher/route_matcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Testing RouteCollection', () {
    test('Building default constructor with empty map should throw in assertion error', () {
      expect(() => RouteCollection(LinkedHashMap()), throwsAssertionError);
    });

    final routeA = RouteConfig('A', path: '/');
    final routeB = RouteConfig('B', path: '/b');
    final subRouteC1 = RouteConfig('C1', path: 'c1');
    final routeC = RouteConfig(
      'C',
      path: '/c',
      children: [subRouteC1],
    );
    final collection = RouteCollection.from(
      [routeA, routeB, routeC],
    );
    test('Calling [routes] should return a list of all route configs', () {
      var expectedRoutes = [routeA, routeB, routeC];
      expect(collection.routes, expectedRoutes);
    });

    test('Calling [containsKey] with existing key should return true', () {
      expect(collection.containsKey('A'), isTrue);
    });

    test('Calling [containsKey] with non-existing key should return false', () {
      expect(collection.containsKey('X'), isFalse);
    });

    test('Extracting sub collection of a branch route should return sub collection', () {
      var expectedCollection = RouteCollection.from([subRouteC1]);
      expect(collection.subCollectionOf('C'), expectedCollection);
    });

    test('Extracting sub collection of a leaf or a non-existing route should throw', () {
      expect(() => collection.subCollectionOf('A'), throwsAssertionError);
      expect(() => collection.subCollectionOf('X'), throwsAssertionError);
    });

    test('Calling [] operator with an existing key should return corresponding route', () {
      expect(collection['A'], routeA);
    });

    test('Calling [] operator with a non-existing key should return null', () {
      expect(collection['X'], isNull);
    });
  });

  group('Testing matching with include prefix matches off', () {
    final routeA = RouteConfig('A', path: '/');
    final routeB = RouteConfig('B', path: '/b');
    final subRouteC1 = RouteConfig('C1', path: 'c1');
    final routeC = RouteConfig(
      'C',
      path: '/c',
      children: [subRouteC1],
    );

    final routeCollection = RouteCollection.from([
      routeA,
      routeB,
      routeC,
    ]);

    final match = RouteMatcher(routeCollection).match;

    test('Should return one match [B]', () {
      final expectedMatches = [
        RouteMatch(
          routeName: 'B',
          key: ValueKey('B'),
          path: '/b',
          stringMatch: '/b',
          segments: ['/', 'b'],
        )
      ];
      expect(match('/b'), expectedMatches);
    });

    test('Should not match', () {
      expect(match('/x'), isNull);
    });

    test('Should return one match with one nested match [C/C1]', () {
      final expectedMatches = [
        RouteMatch(
          routeName: 'C',
          path: '/c',
          stringMatch: '/c',
          key: ValueKey('C'),
          segments: ['/', 'c'],
          children: [
            RouteMatch(
              routeName: 'C1',
              path: 'c1',
              stringMatch: 'c1',
              key: ValueKey('C1'),
              segments: ['c1'],
            )
          ],
        )
      ];
      expect(match('/c/c1'), expectedMatches);
    });

    test('Incomplete match Should return null', () {
      expect(match('/c/c1/x'), isNull);
    });
  });

  group('Testing matching with include prefix matches on', () {
    final routeA = RouteConfig('A', path: '/');
    final routeB = RouteConfig('B', path: '/b');
    final routeB1 = RouteConfig('B1', path: '/b/b1');
    final subRouteC1 = RouteConfig('C1', path: 'c1');
    final subRouteD0 = RouteConfig('D0', path: '');
    final subRouteD1 = RouteConfig('D1', path: 'd1');
    final routeD = RouteConfig(
      'D',
      path: '/d',
      children: [subRouteD0, subRouteD1],
    );
    final routeC = RouteConfig(
      'C',
      path: '/c',
      children: [subRouteC1],
    );

    final routeCollection = RouteCollection.from(
      [routeA, routeB, routeB1, routeC, routeD],
    );

    final match = RouteMatcher(routeCollection).match;

    test('Should return two matches [A,B]', () {
      final expectedMatches = [
        RouteMatch(
          routeName: 'A',
          path: '/',
          stringMatch: '/',
          key: ValueKey('A'),
          segments: ['/'],
        ),
        RouteMatch(
          routeName: 'B',
          path: '/b',
          stringMatch: '/b',
          key: ValueKey('B'),
          segments: ['/', 'b'],
        )
      ];
      expect(match('/b', includePrefixMatches: true), expectedMatches);
    });

    test('Should return two prefix matches with one nested match [A, C/C1]', () {
      final expectedMatches = [
        RouteMatch(
          routeName: 'A',
          path: '/',
          stringMatch: '/',
          key: ValueKey('A'),
          segments: ['/'],
        ),
        RouteMatch(
          routeName: 'C',
          path: '/c',
          stringMatch: '/c',
          key: ValueKey('C'),
          segments: ['/', 'c'],
          children: [
            RouteMatch(
              routeName: 'C1',
              path: 'c1',
              stringMatch: 'c1',
              key: ValueKey('C1'),
              segments: ['c1'],
            )
          ],
        )
      ];
      expect(match('/c/c1', includePrefixMatches: true), expectedMatches);
    });

    test('Should return two prefix matches with one nested match [A, D/D0]', () {
      final expectedMatches = [
        RouteMatch(
          routeName: 'A',
          path: '/',
          stringMatch: '/',
          key: ValueKey('A'),
          segments: ['/'],
        ),
        RouteMatch(
          routeName: 'D',
          path: '/d',
          stringMatch: '/d',
          key: ValueKey('D'),
          segments: ['/', 'd'],
          children: [
            RouteMatch(
              routeName: 'D0',
              path: '',
              stringMatch: '',
              key: ValueKey('D0'),
              segments: [],
            ),
          ],
        )
      ];
      expect(match('/d', includePrefixMatches: true), expectedMatches);
    });

    test('Should return two matches with two nested matches including empty path [A, D/D0/D1]', () {
      final expectedMatches = [
        RouteMatch(
          routeName: 'A',
          path: '/',
          stringMatch: '/',
          key: ValueKey('A'),
          segments: ['/'],
        ),
        RouteMatch(
          routeName: 'D',
          path: '/d',
          stringMatch: '/d',
          key: ValueKey('D'),
          segments: ['/', 'd'],
          children: [
            RouteMatch(
              path: '',
              stringMatch: '',
              key: ValueKey('D0'),
              routeName: 'D0',
              segments: [],
            ),
            RouteMatch(
              routeName: 'D1',
              stringMatch: 'd1',
              key: ValueKey('D1'),
              path: 'd1',
              segments: ['d1'],
            )
          ],
        )
      ];
      expect(match('/d/d1', includePrefixMatches: true), expectedMatches);
    });

    test('Incomplete match Should return null', () {
      expect(match('/c/c1/undefined', includePrefixMatches: true), isNull);
    });

    test('Should return two prefix matches and one full match [A, B, B/B1]', () {
      final expectedMatches = [
        RouteMatch(
          routeName: 'A',
          key: ValueKey('A'),
          stringMatch: '/',
          path: '/',
          segments: ['/'],
        ),
        RouteMatch(
          routeName: 'B',
          key: ValueKey('B'),
          stringMatch: '/b',
          path: '/b',
          segments: ['/', 'b'],
        ),
        RouteMatch(
          routeName: 'B1',
          key: ValueKey('B1'),
          stringMatch: '/b/b1',
          path: '/b/b1',
          segments: ['/', 'b', 'b1'],
        )
      ];
      expect(match('/b/b1', includePrefixMatches: true), expectedMatches);
    });
  });

  group('Testing WildCard matching', () {
    final routeA = RouteConfig('A', path: '/');
    final routeB = RouteConfig('B', path: '/b');
    final subRouteC1 = RouteConfig('C1', path: 'c1');
    final routeC = RouteConfig(
      'C',
      path: '/c',
      children: [subRouteC1],
    );
    final wcRoute = RouteConfig('WC', path: '*');
    final prefixedWcRoute = RouteConfig('PWC', path: '/d/*');

    final routeCollection = RouteCollection.from(
      [routeA, routeB, routeC, prefixedWcRoute, wcRoute],
    );
    final match = RouteMatcher(routeCollection).match;

    test('Should match wildcard [WC]', () {
      final expectedMatches = [
        RouteMatch(
          routeName: 'WC',
          key: ValueKey('WC'),
          stringMatch: '/x/y',
          path: '*',
          segments: ['/', 'x', 'y'],
        )
      ];
      expect(match('/x/y', includePrefixMatches: true), expectedMatches);
    });

    test('Incomplete match should return [WC]', () {
      final expectedMatches = [
        RouteMatch(
          routeName: 'WC',
          key: ValueKey('WC'),
          stringMatch: '/c/c1/x',
          path: '*',
          segments: ['/', 'c', 'c1', 'x'],
        )
      ];
      expect(match('/c/c1/x', includePrefixMatches: true), expectedMatches);
    });

    test('Should match prefixed wildcard route [PWC]', () {
      final expectedMatches = [
        RouteMatch(
          path: '/d/*',
          key: ValueKey('PWC'),
          stringMatch: '/d/x/y',
          routeName: 'PWC',
          segments: ['/', 'd', 'x', 'y'],
        )
      ];
      expect(match('/d/x/y'), expectedMatches);
    });
  });

  group('Testing redirect routes', () {
    final routeA = RouteConfig('A', path: '/a');
    final routeARedirect = RouteConfig('AR', path: '/', redirectTo: '/a', fullMatch: true);
    final subRouteC1 = RouteConfig('C1', path: 'c1');
    final subRouteC1Redirect = RouteConfig('C1R', path: '', redirectTo: 'c1', fullMatch: true);
    final routeC = RouteConfig(
      'C',
      path: '/c',
      children: [subRouteC1Redirect, subRouteC1],
    );
    final routeAWCRedirect = RouteConfig('A-WC-R', path: '*', redirectTo: '/a', fullMatch: true);

    final routeCollection = RouteCollection.from(
      [routeA, routeC, routeARedirect, routeAWCRedirect],
    );
    final match = RouteMatcher(routeCollection).match;

    test('Should match route [A]', () {
      final expectedMatches = [
        RouteMatch(
          routeName: 'A',
          key: ValueKey('A'),
          stringMatch: '/a',
          path: '/a',
          segments: ['/'],
          redirectedFrom: '/',
        )
      ];
      expect(match('/'), expectedMatches);
    });

    test('Should match route [C/C1]', () {
      final expectedMatches = [
        RouteMatch(
          routeName: 'C',
          key: ValueKey('C'),
          stringMatch: '/c',
          path: '/c',
          segments: ['/', 'c'],
          children: [
            RouteMatch(
              routeName: 'C1',
              key: ValueKey('C1'),
              stringMatch: 'c1',
              path: 'c1',
              segments: ['c1'],
              redirectedFrom: '/c',
            )
          ],
        ),
      ];
      expect(match('/c'), expectedMatches);
    });

    test('Should match route [A]', () {
      final expectedMatches = [
        RouteMatch(
          routeName: 'A',
          key: ValueKey('A'),
          stringMatch: '/a',
          path: '/a',
          segments: ['*'],
          redirectedFrom: '*',
        )
      ];
      expect(match('/x/y'), expectedMatches);
    });
  });

  group('Testing Path parameters parsing', () {
    final routeA = RouteConfig('A', path: '/a/:id');
    final routeB = RouteConfig('B', path: '/b/:id/n/:type');
    final subRouteC1 = RouteConfig('C1', path: ':id');

    final routeC = RouteConfig(
      'C',
      path: '/c',
      children: [subRouteC1],
    );

    final routeCollection = RouteCollection.from(
      [routeA, routeB, routeC],
    );
    final match = RouteMatcher(routeCollection).match;

    test('Should match route [A] and extract path param {id:1}', () {
      final expectedMatches = [
        RouteMatch(
          routeName: 'A',
          key: ValueKey('A'),
          stringMatch: '/a/1',
          path: '/a/:id',
          segments: ['/', 'a', '1'],
          pathParams: Parameters({'id': '1'}),
        )
      ];
      expect(match('/a/1'), expectedMatches);
    });

    test('Should match route [B] and extract path params {id:1, type:none}', () {
      final expectedMatches = [
        RouteMatch(
          routeName: 'B',
          key: ValueKey('B'),
          stringMatch: '/b/1/n/none',
          path: '/b/:id/n/:type',
          segments: ['/', 'b', '1', 'n', 'none'],
          pathParams: Parameters({
            'id': '1',
            'type': 'none',
          }),
        )
      ];
      expect(match('/b/1/n/none'), expectedMatches);
    });

    test('Should match route [C]', () {
      final expectedMatches = [
        RouteMatch(
          routeName: 'C',
          key: ValueKey('C'),
          stringMatch: '/c',
          path: '/c',
          segments: ['/', 'c'],
          children: [
            RouteMatch(
              path: ':id',
              routeName: 'C1',
              key: ValueKey('C1'),
              stringMatch: '1',
              segments: ['1'],
              pathParams: Parameters({'id': '1'}),
            )
          ],
        )
      ];
      expect(match('/c/1'), expectedMatches);
    });
  });

  group('Testing query parameters parsing', () {
    final routeA = RouteConfig('A', path: '/a');
    final routeB = RouteConfig('B', path: '/b');
    final routeB1 = RouteConfig('B1', path: '/b/b1');
    final subRouteC1 = RouteConfig('C1', path: 'c1');
    final routeC = RouteConfig(
      'C',
      path: '/c',
      children: [subRouteC1],
    );

    final routeCollection = RouteCollection.from(
      [routeA, routeB, routeB1, routeC],
    );
    final match = RouteMatcher(routeCollection).match;

    test('Should match route [A] and extract query param {foo:bar}', () {
      final expectedMatches = [
        RouteMatch(
          key: ValueKey('A'),
          stringMatch: '/a',
          routeName: 'A',
          path: '/a',
          segments: ['/', 'a'],
          queryParams: Parameters({'foo': 'bar'}),
        )
      ];
      expect(match('/a?foo=bar'), expectedMatches);
    });

    test('Should match routes [B,B1] and extract query params {foo:bar, bar:baz} for both', () {
      final expectedMatches = [
        RouteMatch(
          key: ValueKey('B'),
          stringMatch: '/b',
          routeName: 'B',
          path: '/b',
          segments: ['/', 'b'],
          queryParams: Parameters({'foo': 'bar', 'bar': 'baz'}),
        ),
        RouteMatch(
          key: ValueKey('B1'),
          stringMatch: '/b/b1',
          routeName: 'B1',
          path: '/b/b1',
          segments: ['/', 'b', 'b1'],
          queryParams: Parameters({'foo': 'bar', 'bar': 'baz'}),
        )
      ];
      expect(match('/b/b1?foo=bar&bar=baz', includePrefixMatches: true), expectedMatches);
    });

    test('Should match route [C/C1] and extract query parameters {foo:bar} for parent and child', () {
      final expectedMatches = [
        RouteMatch(
          routeName: 'C',
          path: '/c',
          stringMatch: '/c',
          key: ValueKey('C'),
          segments: ['/', 'c'],
          queryParams: Parameters({'foo': 'bar'}),
          children: [
            RouteMatch(
              key: ValueKey('C1'),
              routeName: 'C1',
              path: 'c1',
              stringMatch: 'c1',
              segments: ['c1'],
              queryParams: Parameters({'foo': 'bar'}),
            )
          ],
        )
      ];
      expect(match('/c/c1?foo=bar'), expectedMatches);
    });

    test('Should match route [A] and extract query param {foo:[bar,baz]}', () {
      final expectedMatches = [
        RouteMatch(
          key: ValueKey('A'),
          stringMatch: '/a',
          routeName: 'A',
          path: '/a',
          segments: ['/', 'a'],
          queryParams: Parameters({
            'foo': ['bar', 'baz']
          }),
        )
      ];

      expect(match('/a?foo=bar&foo=baz'), expectedMatches);
    });
  });
}
