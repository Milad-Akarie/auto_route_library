import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/matcher/route_matcher.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Testing RouteCollection', () {
    test('Building default constructor with empty map should throw in assertion error', () {
      expect(() => RouteCollection({}), throwsAssertionError);
    });

    final routeA = TestRoute('A', path: '/');
    final routeB = TestRoute('B', path: '/b');
    final subRouteC1 = TestRoute('C1', path: 'c1');
    final routeC = TestRoute(
      'C',
      path: '/c',
      children: [subRouteC1],
    );
    final collection = RouteCollection.from(
      [routeA, routeB, routeC],
      root: true,
    );

    test('Creating root RouteCollection with a root route not starting with "/" should throw', () {
      expect(()=> RouteCollection.from([TestRoute('A', path: 'a')], root: true), throwsFlutterError);
    });

    test('Creating sub RouteCollection with a sub route starting with "/" should throw', () {
      expect(()=> RouteCollection.from([TestRoute('A', path: '/a')], root: false), throwsFlutterError);
    });

    test('Calling [routes] should return a list of all route configs', () {
      var expectedRoutes = [routeA, routeB, routeC];
      expect(collection.routes, expectedRoutes);
    });

    test('Calling findPathTo to C1 should return a list of route trails[C,C1]', () {
      expect(collection.findPathTo('C1'), [routeC, subRouteC1]);
    });

    test('Calling [containsKey] with existing key should return true', () {
      expect(collection.containsKey('A'), isTrue);
    });

    test('Calling [containsKey] with non-existing key should return false', () {
      expect(collection.containsKey('X'), isFalse);
    });

    test('Extracting sub collection of a branch route should return sub collection', () {
      var expectedCollection = RouteCollection.from([subRouteC1], root: false);
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
    test('call RouteMatch.fromRedirect should return true', () {
      expect(
          const RouteMatch(
            name: 'A',
            segments: ['a'],
            path: 'a',
            redirectedFrom: '/',
            stringMatch: 'a',
            key: ValueKey('a'),
          ).fromRedirect,
          isTrue);
    });

    test('call RouteMatch.hasEmptyPath should return true', () {
      expect(
          const RouteMatch(
            name: 'A',
            segments: [''],
            path: '',
            stringMatch: '',
            key: ValueKey(''),
          ).hasEmptyPath,
          isTrue);
    });
  });

  group('Testing matching with include prefix matches off', () {
    final routeA = TestRoute('A', path: '/');
    final routeB = TestRoute('B', path: '/b');
    final subRouteC1 = TestRoute('C1', path: 'c1');
    final routeC = TestRoute(
      'C',
      path: '/c',
      children: [subRouteC1],
    );

    final routeCollection = RouteCollection.from(
      [
        routeA,
        routeB,
        routeC,
      ],
      root: true,
    );

    final match = RouteMatcher(routeCollection).match;

    test('Should return one match [B]', () {
      final expectedMatches = [
        const RouteMatch(
          name: 'B',
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
        const RouteMatch(
          name: 'C',
          path: '/c',
          stringMatch: '/c',
          key: ValueKey('C'),
          segments: ['/', 'c'],
          children: [
            RouteMatch(
              name: 'C1',
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
    final routeA = TestRoute('A', path: '/');
    final routeB = TestRoute('B', path: '/b');
    final routeB1 = TestRoute('B1', path: '/b/b1');
    final subRouteC1 = TestRoute('C1', path: 'c1');
    final subRouteD0 = TestRoute('D0', path: '');
    final subRouteD1 = TestRoute('D1', path: 'd1');
    final routeD = TestRoute(
      'D',
      path: '/d',
      children: [subRouteD0, subRouteD1],
    );
    final routeC = TestRoute(
      'C',
      path: '/c',
      children: [subRouteC1],
    );

    final routeCollection = RouteCollection.from(
      [routeA, routeB, routeB1, routeC, routeD],
      root: true,
    );

    final match = RouteMatcher(routeCollection).match;

    test('Should return two matches [A,B]', () {
      final expectedMatches = [
        const RouteMatch(
          name: 'A',
          path: '/',
          stringMatch: '/',
          key: ValueKey('A'),
          segments: ['/'],
        ),
        const RouteMatch(
          name: 'B',
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
        const RouteMatch(
          name: 'A',
          path: '/',
          stringMatch: '/',
          key: ValueKey('A'),
          segments: ['/'],
        ),
        const RouteMatch(
          name: 'C',
          path: '/c',
          stringMatch: '/c',
          key: ValueKey('C'),
          segments: ['/', 'c'],
          children: [
            RouteMatch(
              name: 'C1',
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
        const RouteMatch(
          name: 'A',
          path: '/',
          stringMatch: '/',
          key: ValueKey('A'),
          segments: ['/'],
        ),
        const RouteMatch(
          name: 'D',
          path: '/d',
          stringMatch: '/d',
          key: ValueKey('D'),
          segments: ['/', 'd'],
          children: [
            RouteMatch(
              name: 'D0',
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
        const RouteMatch(
          name: 'A',
          path: '/',
          stringMatch: '/',
          key: ValueKey('A'),
          segments: ['/'],
        ),
        const RouteMatch(
          name: 'D',
          path: '/d',
          stringMatch: '/d',
          key: ValueKey('D'),
          segments: ['/', 'd'],
          children: [
            RouteMatch(
              path: '',
              stringMatch: '',
              key: ValueKey('D0'),
              name: 'D0',
              segments: [],
            ),
            RouteMatch(
              name: 'D1',
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
        const RouteMatch(
          name: 'A',
          key: ValueKey('A'),
          stringMatch: '/',
          path: '/',
          segments: ['/'],
        ),
        const RouteMatch(
          name: 'B',
          key: ValueKey('B'),
          stringMatch: '/b',
          path: '/b',
          segments: ['/', 'b'],
        ),
        const RouteMatch(
          name: 'B1',
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
    final routeA = TestRoute('A', path: '/');
    final routeB = TestRoute('B', path: '/b');
    final subRouteC1 = TestRoute('C1', path: 'c1');
    final routeC = TestRoute(
      'C',
      path: '/c',
      children: [subRouteC1],
    );
    final wcRoute = TestRoute('WC', path: '*');
    final prefixedWcRoute = TestRoute('PWC', path: '/d/*');

    final routeCollection = RouteCollection.from(
      [routeA, routeB, routeC, prefixedWcRoute, wcRoute],
      root: true,
    );
    final match = RouteMatcher(routeCollection).match;

    test('Should match wildcard [WC]', () {
      final expectedMatches = [
        const RouteMatch(
          name: 'WC',
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
        const RouteMatch(
          name: 'WC',
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
        const RouteMatch(
          path: '/d/*',
          key: ValueKey('PWC'),
          stringMatch: '/d/x/y',
          name: 'PWC',
          segments: ['/', 'd', 'x', 'y'],
        )
      ];
      expect(match('/d/x/y'), expectedMatches);
    });
  });

  group('Testing redirect routes', () {
    final routeA = TestRoute('A', path: '/a');
    final routeARedirect = TestRoute('AR', path: '/', redirectTo: '/a', fullMatch: true);

    final subRouteC1 = TestRoute('C1', path: 'c1');
    final subRouteC1Redirect = TestRoute('C1R', path: '', redirectTo: 'c1', fullMatch: true);

    final routeC = TestRoute(
      'C',
      path: '/c',
      children: [subRouteC1Redirect, subRouteC1],
    );
    final routeAWCRedirect = TestRoute('A-WC-R', path: '*', redirectTo: '/a', fullMatch: true);

    final routeCollection = RouteCollection.from(
      [routeA, routeC, routeARedirect, routeAWCRedirect],
      root: true,
    );
    final match = RouteMatcher(routeCollection).match;

    test('Should match route [A]', () {
      final expectedMatches = [
        const RouteMatch(
          name: 'A',
          key: ValueKey('A'),
          stringMatch: '/a',
          path: '/a',
          segments: ['/', 'a'],
          redirectedFrom: '/',
        )
      ];
      expect(match('/'), expectedMatches);
    });

    test('Should match route [C/C1]', () {
      final expectedMatches = [
        const RouteMatch(
          name: 'C',
          key: ValueKey('C'),
          stringMatch: '/c',
          path: '/c',
          segments: ['/', 'c'],
          children: [
            RouteMatch(
              name: 'C1',
              key: ValueKey('C1'),
              stringMatch: 'c1',
              path: 'c1',
              segments: ['c1'],
              redirectedFrom: '',
            )
          ],
        ),
      ];
      expect(match('/c'), expectedMatches);
    });

    final match2 = RouteMatcher(
      RouteCollection.from(
        [
          TestRoute('A', path: '/a', children: [
            TestRoute('AR', path: 'r', redirectTo: ''),
            TestRoute('A1', path: ''),
          ]),
        ],
        root: true,
      ),
    ).match;

    test('Should match route [A/A1] subRedirect to empty path', () {
      final expectedMatches = [
        const RouteMatch(
          name: 'A',
          key: ValueKey('A'),
          stringMatch: '/a',
          path: '/a',
          segments: ['/', 'a'],
          children: [
            RouteMatch(
              name: 'A1',
              key: ValueKey('A1'),
              stringMatch: '',
              path: '',
              segments: [],
              redirectedFrom: 'r',
            )
          ],
        )
      ];
      expect(match2('/a/r'), expectedMatches);
    });
  });

  group('Testing Path parameters parsing', () {
    final routeA = TestRoute('A', path: '/a/:id');
    final routeB = TestRoute('B', path: '/b/:id/n/:type');
    final subRouteC1 = TestRoute('C1', path: ':id');

    final routeC = TestRoute(
      'C',
      path: '/c',
      children: [subRouteC1],
    );

    final routeCollection = RouteCollection.from(
      [routeA, routeB, routeC],
      root: true,
    );
    final match = RouteMatcher(routeCollection).match;

    test('Should match route [A] and extract path param {id:1}', () {
      final expectedMatches = [
        const RouteMatch(
          name: 'A',
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
        const RouteMatch(
          name: 'B',
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
        const RouteMatch(
          name: 'C',
          key: ValueKey('C'),
          stringMatch: '/c',
          path: '/c',
          segments: ['/', 'c'],
          children: [
            RouteMatch(
              path: ':id',
              name: 'C1',
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
    final routeA = TestRoute('A', path: '/a');
    final routeB = TestRoute('B', path: '/b');
    final routeB1 = TestRoute('B1', path: '/b/b1');
    final subRouteC1 = TestRoute('C1', path: 'c1');
    final routeC = TestRoute(
      'C',
      path: '/c',
      children: [subRouteC1],
    );

    final routeCollection = RouteCollection.from(
      [routeA, routeB, routeB1, routeC],
      root: true,
    );
    final match = RouteMatcher(routeCollection).match;

    test('Should match route [A] and extract query param {foo:bar}', () {
      final expectedMatches = [
        const RouteMatch(
          key: ValueKey('A'),
          stringMatch: '/a',
          name: 'A',
          path: '/a',
          segments: ['/', 'a'],
          queryParams: Parameters({'foo': 'bar'}),
        )
      ];
      expect(match('/a?foo=bar'), expectedMatches);
    });

    test('Should match routes [B,B1] and extract query params {foo:bar, bar:baz} for both', () {
      final expectedMatches = [
        const RouteMatch(
          key: ValueKey('B'),
          stringMatch: '/b',
          name: 'B',
          path: '/b',
          segments: ['/', 'b'],
          queryParams: Parameters({'foo': 'bar', 'bar': 'baz'}),
        ),
        const RouteMatch(
          key: ValueKey('B1'),
          stringMatch: '/b/b1',
          name: 'B1',
          path: '/b/b1',
          segments: ['/', 'b', 'b1'],
          queryParams: Parameters({'foo': 'bar', 'bar': 'baz'}),
        )
      ];
      expect(match('/b/b1?foo=bar&bar=baz', includePrefixMatches: true), expectedMatches);
    });

    test('Should match route [C/C1] and extract query parameters {foo:bar} for parent and child', () {
      final expectedMatches = [
        const RouteMatch(
          name: 'C',
          path: '/c',
          stringMatch: '/c',
          key: ValueKey('C'),
          segments: ['/', 'c'],
          queryParams: Parameters({'foo': 'bar'}),
          children: [
            RouteMatch(
              key: ValueKey('C1'),
              name: 'C1',
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
        const RouteMatch(
          key: ValueKey('A'),
          stringMatch: '/a',
          name: 'A',
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
