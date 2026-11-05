import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// flutter/flutter#128644: go_router tried only the first of two sibling
// sub-routes that both take a path param, so the second was unreachable.
// Setup: a parent '/items' with children 'first/:id' and 'second/:name', and
// a sibling pair 'x/:id' and 'x/:name/details'.
// Steps: open each url, and push each route by its name with params.
// Should: every url shows its own page with its own param.
PageInfo _page(String name, String param) => .new(
  name,
  builder: (data) => Text('$name ${data.params.getString(param)}'),
);

void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
        ),
        AutoRoute(
          path: '/items',
          page: PageInfo('ItemsRoute', builder: (_) => const AutoRouter()),
          children: [
            AutoRoute(path: 'first/:id', page: _page('FirstRoute', 'id')),
            AutoRoute(path: 'second/:name', page: _page('SecondRoute', 'name')),
            AutoRoute(path: 'x/:id', page: _page('XRoute', 'id')),
            AutoRoute(
              path: 'x/:name/details',
              page: _page('XDetailsRoute', 'name'),
            ),
          ],
        ),
      ],
    );
  });

  for (final (url, text) in [
    ('/items/first/7', 'FirstRoute 7'),
    ('/items/second/ann', 'SecondRoute ann'),
    ('/items/x/7', 'XRoute 7'),
    ('/items/x/ann/details', 'XDetailsRoute ann'),
  ]) {
    testWidgets('opening $url shows $text', (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      unawaited(router.navigatePath(url));
      await tester.pumpAndSettle();
      expect(find.text(text), findsOneWidget);
      expect(router.currentUrl, url);
    });
  }

  testWidgets(
    'the second sibling route is reached by name and shows its own param',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      unawaited(
        router.push(
          const NamedRoute(
            'ItemsRoute',
            children: [
              NamedRoute('SecondRoute', params: {'name': 'bob'}),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('SecondRoute bob'), findsOneWidget);
      expect(router.currentUrl, '/items/second/bob');
    },
  );
}
