import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/182441
  // In go_router_builder, a relative route declared under several routes
  // always opened under the first of them, even when pushed from another
  // one.
  // auto_route has no relative route. The same thing is one page declared as
  // a child of several routes: here the reviews page, under both the home
  // shell and the product shell.
  // Steps: open /home, push ReviewsRoute from the home page and go back.
  // Push product 1, then push ReviewsRoute from the product page.
  // Should: each push opens ReviewsRoute under the page it was pushed from.
  testWidgets(
    'A page declared under two routes opens under the one it is pushed from',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef.shell(
            name: 'HomeRoute',
            path: '/home',
            children: [
              _screen('HomeScreenRoute', ''),
              _screen('ReviewsRoute', 'reviews'),
            ],
          ),
          NamedRouteDef.shell(
            name: 'ProductRoute',
            path: '/products/:id',
            children: [
              _screen('ProductScreenRoute', ''),
              _screen('ReviewsRoute', 'reviews'),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router, initialLink: '/home');

      Future<String> pushReviewsFrom(String page) async {
        tester
            .element(find.text(page))
            .router
            .push(const NamedRoute('ReviewsRoute'))
            .ignore();
        await tester.pumpAndSettle();
        expect(find.text('ReviewsRoute'), findsOneWidget);
        return router.currentUrl;
      }

      final fromHome = await pushReviewsFrom('HomeScreenRoute');
      await router.maybePopTop();
      await tester.pumpAndSettle();
      router.push(const NamedRoute('ProductRoute', params: {'id': 1})).ignore();
      await tester.pumpAndSettle();
      final fromProduct = await pushReviewsFrom('ProductScreenRoute');

      expect(tester.takeException(), isNull);
      expect((fromHome, fromProduct), ('/home/reviews', '/products/1/reviews'));
      expect(router.stack.map((page) => page.name), [
        'HomeRoute',
        'ProductRoute',
      ]);
    },
  );
}

NamedRouteDef _screen(String name, String path) =>
    .new(name: name, path: path, builder: (_, _) => Text(name));
