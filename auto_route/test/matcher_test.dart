import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/matcher/route_matcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Testing RouteCollection', () {
    test('Building default constructor with empty map should throw in assertion error', () {
      expect(() => RouteCollection.fromList(const []), throwsAssertionError);
    });

    final routeA = TestRoute('A', path: '/');
    final routeB = TestRoute('B', path: '/b');
    final subRouteC1 = TestRoute('C1', path: 'c1');
    final routeC = TestRoute(
      'C',
      path: '/c',
      children: [subRouteC1],
    );
    final collection = RouteCollection.fromList(
      [routeA, routeB, routeC],
      root: true,
    );

    test('Creating root RouteCollection with a root route not starting with "/" should throw', () {
      expect(() => RouteCollection.fromList([TestRoute('A', path: 'a')], root: true), throwsFlutterError);
    });

    test('Creating sub RouteCollection with a sub route starting with "/" should throw', () {
      expect(
        () => RouteCollection.fromList([TestRoute('A', path: '/a')], root: false),
        throwsFlutterError,
      );
    });

    test('Auto-generated root paths for routes marked as initial should be "/"', () {
      expect(
        RouteCollection.fromList(
          [TestRoute('A', initial: true)],
          root: true,
        ).routes.first.path,
        '/',
      );
    });

    test('Auto-generated sub-paths for routes marked as initial should be empty""', () {
      expect(
        RouteCollection.fromList(
          [TestRoute('A', initial: true)],
          root: false,
        ).routes.first.path,
        '',
      );
    });

    test('Creating a RouteCollection with more than one routes marked as initial should throw', () {
      expect(
        () => RouteCollection.fromList(
          [
            TestRoute('A', path: '/a', initial: true),
            TestRoute('B', path: '/b', initial: true),
          ],
          root: true,
        ),
        throwsFlutterError,
      );
    });

    test(
        'Creating a root RouteCollection with no initialPath with initial set to true should add a RedirectRoute(path:/)',
        () {
      final firstResolvedRoute = RouteCollection.fromList(
        [TestRoute('A', path: '/a', initial: true)],
        root: true,
      ).routes.first;
      expect(firstResolvedRoute, isA<RedirectRoute>());
      expect(firstResolvedRoute.path, '/');
    });

    test(
        'Creating a sub RouteCollection with no initialPath with initial set to true should add a RedirectRoute(path:"")',
        () {
      final firstResolvedRoute = RouteCollection.fromList(
        [TestRoute('A', path: 'a', initial: true)],
        root: false,
      ).routes.first;
      expect(firstResolvedRoute, isA<RedirectRoute>());
      expect(firstResolvedRoute.path, '');
    });

    test('Calling [routes] should return a list of all route configs', () {
      var expectedRoutes = [routeA, routeB, routeC];
      expect(collection.routes, expectedRoutes);
    });

    test('RouteCollection.fromList root should not remove multiple redirects', () {
      final routeCollection = RouteCollection.fromList(
        [
          TestRoute('A', path: '/'),
          TestRoute('B', path: '/b'),
          RedirectRoute(path: '/c', redirectTo: '/b'),
          TestRoute('D', path: '/d'),
          RedirectRoute(path: '*', redirectTo: '/'),
        ],
        root: true,
      );
      expect(routeCollection.routes.length, 5);
    });

    test('RouteCollection.fromList non root should not remove multiple redirects', () {
      final routeCollection = RouteCollection.fromList(
        [
          TestRoute('A', path: 'a'),
          TestRoute('B', path: 'b'),
          RedirectRoute(path: 'c', redirectTo: 'b'),
          TestRoute('D', path: 'd'),
          RedirectRoute(path: '*', redirectTo: 'a'),
        ],
        root: false,
      );
      expect(routeCollection.routes.length, 5);
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
      var expectedCollection = RouteCollection.fromList([subRouteC1], root: false);
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
          RouteMatch(
            config: routeA,
            segments: const ['a'],
            redirectedFrom: '/',
            stringMatch: 'a',
            key: const ValueKey('a'),
          ).fromRedirect,
          isTrue);
    });

    test('call RouteMatch.hasEmptyPath should return true', () {
      expect(
          RouteMatch(
            config: TestRoute('A', path: ''),
            segments: const [''],
            stringMatch: '',
            key: const ValueKey(''),
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

    final routeCollection = RouteCollection.fromList(
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
        RouteMatch(
          config: routeB,
          key: const ValueKey('B'),
          stringMatch: '/b',
          segments: const ['/', 'b'],
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
          config: routeC,
          stringMatch: '/c',
          key: const ValueKey('C'),
          segments: const ['/', 'c'],
          children: [
            RouteMatch(
              config: subRouteC1,
              stringMatch: 'c1',
              key: const ValueKey('C1'),
              segments: const ['c1'],
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

    final routeCollection = RouteCollection.fromList(
      [routeA, routeB, routeB1, routeC, routeD],
      root: true,
    );

    final match = RouteMatcher(routeCollection).match;

    test('Should return two matches [A,B]', () {
      final expectedMatches = [
        RouteMatch(
          config: routeA,
          stringMatch: '/',
          key: const ValueKey('A'),
          segments: const ['/'],
        ),
        RouteMatch(
          config: routeB,
          stringMatch: '/b',
          key: const ValueKey('B'),
          segments: const ['/', 'b'],
        )
      ];
      expect(match('/b', includePrefixMatches: true), expectedMatches);
    });

    test('Should return two prefix matches with one nested match [A, C/C1]', () {
      final expectedMatches = [
        RouteMatch(
          config: routeA,
          stringMatch: '/',
          key: const ValueKey('A'),
          segments: const ['/'],
        ),
        RouteMatch(
          config: routeC,
          stringMatch: '/c',
          key: const ValueKey('C'),
          segments: const ['/', 'c'],
          children: [
            RouteMatch(
              config: subRouteC1,
              stringMatch: 'c1',
              key: const ValueKey('C1'),
              segments: const ['c1'],
            )
          ],
        )
      ];
      expect(match('/c/c1', includePrefixMatches: true), expectedMatches);
    });

    test('Should return two prefix matches with one nested match [A, D/D0]', () {
      final expectedMatches = [
        RouteMatch(
          config: routeA,
          stringMatch: '/',
          key: const ValueKey('A'),
          segments: const ['/'],
        ),
        RouteMatch(
          config: routeD,
          stringMatch: '/d',
          key: const ValueKey('D'),
          segments: const ['/', 'd'],
          children: [
            RouteMatch(
              config: subRouteD0,
              stringMatch: '',
              key: const ValueKey('D0'),
              segments: const [],
            ),
          ],
        )
      ];
      expect(match('/d', includePrefixMatches: true), expectedMatches);
    });

    test('Should return two matches with two nested matches including empty path [A, D/D0/D1]', () {
      final expectedMatches = [
        RouteMatch(
          config: routeA,
          stringMatch: '/',
          key: const ValueKey('A'),
          segments: const ['/'],
        ),
        RouteMatch(
          config: routeD,
          stringMatch: '/d',
          key: const ValueKey('D'),
          segments: const ['/', 'd'],
          children: [
            RouteMatch(
              config: subRouteD0,
              stringMatch: '',
              key: const ValueKey('D0'),
              segments: const [],
            ),
            RouteMatch(
              config: subRouteD1,
              stringMatch: 'd1',
              key: const ValueKey('D1'),
              segments: const ['d1'],
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
          config: routeA,
          key: const ValueKey('A'),
          stringMatch: '/',
          segments: const ['/'],
        ),
        RouteMatch(
          config: routeB,
          key: const ValueKey('B'),
          stringMatch: '/b',
          segments: const ['/', 'b'],
        ),
        RouteMatch(
          config: routeB1,
          key: const ValueKey('B1'),
          stringMatch: '/b/b1',
          segments: const ['/', 'b', 'b1'],
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

    final routeCollection = RouteCollection.fromList(
      [routeA, routeB, routeC, prefixedWcRoute, wcRoute],
      root: true,
    );
    final match = RouteMatcher(routeCollection).match;

    test('Should match wildcard [WC]', () {
      final expectedMatches = [
        RouteMatch(
          config: wcRoute,
          key: const ValueKey('WC'),
          stringMatch: '/x/y',
          segments: const ['/', 'x', 'y'],
        )
      ];
      expect(match('/x/y', includePrefixMatches: true), expectedMatches);
    });

    test('Incomplete match should return [WC]', () {
      final expectedMatches = [
        RouteMatch(
          config: wcRoute,
          key: const ValueKey('WC'),
          stringMatch: '/c/c1/x',
          segments: const ['/', 'c', 'c1', 'x'],
        )
      ];
      expect(match('/c/c1/x', includePrefixMatches: true), expectedMatches);
    });

    test('Should match prefixed wildcard route [PWC]', () {
      final expectedMatches = [
        RouteMatch(
          config: prefixedWcRoute,
          key: const ValueKey('PWC'),
          stringMatch: '/d/x/y',
          segments: const ['/', 'd', 'x', 'y'],
        )
      ];
      expect(match('/d/x/y'), expectedMatches);
    });
  });

  group('Testing redirect routes', () {
    final routeA = TestRoute('A', path: '/a');
    final routeARedirect = RedirectRoute(path: '/', redirectTo: '/a');
    final subRouteC1 = TestRoute('C1', path: 'c1');
    final subRouteC1Redirect = RedirectRoute(path: '', redirectTo: 'c1');

    final routeC = TestRoute(
      'C',
      path: '/c',
      children: [subRouteC1Redirect, subRouteC1],
    );
    final routeAWCRedirect = RedirectRoute(path: '*', redirectTo: '/a');

    final routeCollection = RouteCollection.fromList(
      [routeA, routeC, routeARedirect, routeAWCRedirect],
      root: true,
    );
    final match = RouteMatcher(routeCollection).match;

    test('Should match route [A]', () {
      final expectedMatches = [
        RouteMatch(
          config: routeA,
          key: const ValueKey('A'),
          stringMatch: '/a',
          segments: const ['/', 'a'],
          redirectedFrom: '/',
        )
      ];
      expect(match('/'), expectedMatches);
    });

    test('Should match route [C/C1]', () {
      final expectedMatches = [
        RouteMatch(
          config: routeC,
          key: const ValueKey('C'),
          stringMatch: '/c',
          segments: const ['/', 'c'],
          children: [
            RouteMatch(
              config: subRouteC1,
              key: const ValueKey('C1'),
              stringMatch: 'c1',
              segments: const ['c1'],
              redirectedFrom: '',
            )
          ],
        ),
      ];
      expect(match('/c'), expectedMatches);
    });

    final match2 = RouteMatcher(
      RouteCollection.fromList(
        [
          TestRoute('A', path: '/a', children: [
            RedirectRoute(path: 'r', redirectTo: ''),
            TestRoute('A1', path: ''),
          ]),
        ],
        root: true,
      ),
    ).match;

    test('Should match route [A/A1] subRedirect to empty path', () {
      final expectedMatches = [
        RouteMatch(
          config: routeA,
          key: const ValueKey('A'),
          stringMatch: '/a',
          segments: const ['/', 'a'],
          children: [
            RouteMatch(
              config: TestRoute('A1', path: ''),
              key: const ValueKey('A1'),
              stringMatch: '',
              segments: const [],
              redirectedFrom: 'r',
            )
          ],
        )
      ];
      expect(match2('/a/r'), expectedMatches);
    });

    test('Should redirect to [/A?foo=bar]', () {
      final match = RouteMatcher(
        RouteCollection.fromList(
          [
            RedirectRoute(path: '/', redirectTo: '/a?foo=bar'),
            routeA,
          ],
          root: true,
        ),
      ).match;
      final expectedMatches = [
        RouteMatch(
          config: routeA,
          key: const ValueKey('A'),
          stringMatch: '/a',
          segments: const ['/', 'a'],
          queryParams: const Parameters({'foo': 'bar'}),
          redirectedFrom: '/',
        )
      ];
      expect(match('/?foo=bar'), expectedMatches);
    });

    test('Should redirect to [/A/:id]', () {
      final routeA = TestRoute('A', path: '/a/:id');
      final match = RouteMatcher(
        RouteCollection.fromList(
          [
            RedirectRoute(path: '/x/:id', redirectTo: '/a/:id'),
            routeA,
          ],
          root: true,
        ),
      ).match;
      final expectedMatches = [
        RouteMatch(
          config: routeA,
          key: const ValueKey('A'),
          stringMatch: '/a/foo',
          segments: const ['/', 'a', 'foo'],
          params: const Parameters({'id': 'foo'}),
          redirectedFrom: '/x/foo',
        )
      ];
      expect(match('/x/foo'), expectedMatches);
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

    final routeCollection = RouteCollection.fromList(
      [routeA, routeB, routeC],
      root: true,
    );
    final match = RouteMatcher(routeCollection).match;

    test('Should match route [A] and extract path param {id:1}', () {
      final expectedMatches = [
        RouteMatch(
          config: routeA,
          key: const ValueKey('A'),
          stringMatch: '/a/1',
          segments: const ['/', 'a', '1'],
          params: const Parameters({'id': '1'}),
        )
      ];
      expect(match('/a/1'), expectedMatches);
    });

    test('Should match route [B] and extract path params {id:1, type:none}', () {
      final expectedMatches = [
        RouteMatch(
          config: routeB,
          key: const ValueKey('B'),
          stringMatch: '/b/1/n/none',
          segments: const ['/', 'b', '1', 'n', 'none'],
          params: const Parameters({
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
          config: routeC,
          key: const ValueKey('C'),
          stringMatch: '/c',
          segments: const ['/', 'c'],
          children: [
            RouteMatch(
              config: subRouteC1,
              key: const ValueKey('C1'),
              stringMatch: '1',
              segments: const ['1'],
              params: const Parameters({'id': '1'}),
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

    final routeCollection = RouteCollection.fromList(
      [routeA, routeB, routeB1, routeC],
      root: true,
    );
    final match = RouteMatcher(routeCollection).match;

    test('Should match route [A] and extract query param {foo:bar}', () {
      final expectedMatches = [
        RouteMatch(
          key: const ValueKey('A'),
          stringMatch: '/a',
          config: routeA,
          segments: const ['/', 'a'],
          queryParams: const Parameters({'foo': 'bar'}),
        )
      ];
      expect(match('/a?foo=bar'), expectedMatches);
    });

    test('Should match routes [B,B1] and extract query params {foo:bar, bar:baz} for both', () {
      final expectedMatches = [
        RouteMatch(
          key: const ValueKey('B'),
          stringMatch: '/b',
          config: routeB,
          segments: const ['/', 'b'],
          queryParams: const Parameters({'foo': 'bar', 'bar': 'baz'}),
        ),
        RouteMatch(
          key: const ValueKey('B1'),
          stringMatch: '/b/b1',
          config: routeB1,
          segments: const ['/', 'b', 'b1'],
          queryParams: const Parameters({'foo': 'bar', 'bar': 'baz'}),
        )
      ];
      expect(match('/b/b1?foo=bar&bar=baz', includePrefixMatches: true), expectedMatches);
    });

    test('Should match route [C/C1] and extract query parameters {foo:bar} for parent and child', () {
      final expectedMatches = [
        RouteMatch(
          config: routeC,
          stringMatch: '/c',
          key: const ValueKey('C'),
          segments: const ['/', 'c'],
          queryParams: const Parameters({'foo': 'bar'}),
          children: [
            RouteMatch(
              key: const ValueKey('C1'),
              config: subRouteC1,
              stringMatch: 'c1',
              segments: const ['c1'],
              queryParams: const Parameters({'foo': 'bar'}),
            )
          ],
        )
      ];
      expect(match('/c/c1?foo=bar'), expectedMatches);
    });

    test('Should match route [A] and extract query param {foo:[bar,baz]}', () {
      final expectedMatches = [
        RouteMatch(
          key: const ValueKey('A'),
          stringMatch: '/a',
          config: routeA,
          segments: const ['/', 'a'],
          queryParams: const Parameters({
            'foo': ['bar', 'baz']
          }),
        )
      ];

      expect(match('/a?foo=bar&foo=baz'), expectedMatches);
    });
  });

  group('Testing matching of nested routes with a wildcard redirect and other redirects at the root', () {
    final cSubRoute = TestRoute(
      'C1',
      path: '',
    );
    final aRoute = TestRoute(
      'A',
      path: '',
    );
    final bRoute = TestRoute(
      'B',
      path: 'b',
    );
    final cRoute = TestRoute(
      'C',
      path: 'c',
      children: [
        cSubRoute,
      ],
    );
    final root = TestRoute(
      'Root',
      path: '/',
      initial: true,
      children: [
        aRoute,
        bRoute,
        RedirectRoute(
          path: 'd',
          redirectTo: 'b',
        ),
        cRoute,
        RedirectRoute(path: '*', redirectTo: ''),
      ],
    );

    final routeCollection = RouteCollection.fromList(
      [root],
      root: true,
    );

    final match = RouteMatcher(routeCollection).match;

    test('Should return correct match for /c', () {
      final expectedMatches = [
        RouteMatch(config: root, key: const ValueKey('Root'), stringMatch: '/', segments: const [
          '/'
        ], children: [
          RouteMatch(
            config: cRoute,
            key: const ValueKey('C'),
            stringMatch: 'c',
            segments: const ['c'],
            children: [
              RouteMatch(
                config: cSubRoute,
                key: const ValueKey('C1'),
                stringMatch: '',
                segments: const [],
              ),
            ],
          )
        ])
      ];
      expect(match('/c'), expectedMatches);
    });

    test('Should return correct match for /d', () {
      final expectedMatches = [
        RouteMatch(config: root, key: const ValueKey('Root'), stringMatch: '/', segments: const [
          '/'
        ], children: [
          RouteMatch(
            config: bRoute,
            key: const ValueKey('B'),
            stringMatch: 'b',
            redirectedFrom: 'd',
            segments: const ['b'],
          )
        ])
      ];
      expect(match('/d'), expectedMatches);
    });

    test('Should return a redirect match for bogus url /adsfadsg', () {
      expect(match('/adsfadsg')?.first.children?.first.redirectedFrom, '*');
    });
  });
}
