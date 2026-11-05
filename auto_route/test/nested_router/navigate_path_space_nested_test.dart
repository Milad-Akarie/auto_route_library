import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import '../named_page.dart';
import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1587
  // Reported: navigateNamed('/search/results/a search term') into a nested
  // router encoded the space once per level, giving 'a%2520search%2520term'
  // and the param 'a%20search%20term'.
  // Steps: '/search' and '/main/search' each host a router with
  // 'results/:term'; navigatePath to each with a space in the term, and a
  // relative navigatePath from inside the nested router.
  // Should: the page gets 'a search term', and the url encodes it once.
  RootStackRouter buildRouter() => .build(
    routes: [
      NamedRouteDef(
        name: 'HomeRoute',
        path: '/',
        builder: (_, _) => const NamedPage('HomeRoute'),
      ),
      NamedRouteDef.shell(
        name: 'SearchRoute',
        path: '/search',
        children: [
          NamedRouteDef(
            name: 'ListRoute',
            path: '',
            builder: (_, _) => const NamedPage('ListRoute'),
          ),
          NamedRouteDef(
            name: 'ResultsRoute',
            path: 'results/:term',
            builder: (_, data) =>
                NamedPage('term ${data.params.getString('term')}'),
          ),
        ],
      ),
      NamedRouteDef.shell(
        name: 'MainRoute',
        path: '/main',
        children: [
          NamedRouteDef.shell(
            name: 'MainSearchRoute',
            path: 'search',
            children: [
              NamedRouteDef(
                name: 'MainListRoute',
                path: '',
                builder: (_, _) => const NamedPage('MainListRoute'),
              ),
              NamedRouteDef(
                name: 'MainResultsRoute',
                path: 'results/:term',
                builder: (_, data) =>
                    NamedPage('term ${data.params.getString('term')}'),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  for (final path in [
    '/search/results/a search term',
    '/main/search/results/a search term',
  ]) {
    testWidgets('navigatePath to $path encodes the space once', (tester) async {
      final router = buildRouter();
      await pumpRouterApp(tester, router);

      unawaited(router.navigatePath(path));
      await tester.pumpAndSettle();

      expect(find.text('term a search term'), findsOneWidget);
      expect(router.urlState.uri.toString(), Uri.encodeFull(path));
    });
  }

  testWidgets(
    'A relative navigatePath with a space inside the nested router encodes it '
    'once',
    (tester) async {
      final router = buildRouter();
      await pumpRouterApp(tester, router, initialLink: '/main/search');

      unawaited(
        tester
            .element(find.text('MainListRoute'))
            .router
            .navigatePath('results/a thing'),
      );
      await tester.pumpAndSettle();

      expect(find.text('term a thing'), findsOneWidget);
      expect(router.urlState.uri.toString(), '/main/search/results/a%20thing');
    },
  );
}
