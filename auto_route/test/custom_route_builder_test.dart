import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

PageInfo _productsPage = PageInfo(
  'ProductsRoute',
  builder: (data) => Scaffold(body: Text('Products page ${data.queryParams.optString('page')}')),
);

void main() {
  // Reproduces https://github.com/Milad-Akarie/auto_route_library/issues/1857
  // Steps: ProductsRoute is a CustomRoute whose customRouteBuilder returns a
  // PageRouteBuilder wrapping the child in a SelectionArea, and the page reads
  // the query param 'page'. Open it with page=1, then replace() it with page=2.
  // Happens: the url changes to page=2, but the page still shows page 1.
  // Should: the page shows page 2, as it does without customRouteBuilder.
  testWidgets('A customRouteBuilder page shows the new query params after replace()', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
        ),
        CustomRoute<dynamic>(
          path: '/products',
          page: _productsPage,
          customRouteBuilder: <T>(context, child, page) => PageRouteBuilder<T>(
            settings: page,
            pageBuilder: (_, _, _) => SelectionArea(child: child),
            transitionsBuilder: TransitionsBuilders.fadeIn,
          ),
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.push(const NamedRoute('ProductsRoute', queryParams: {'page': '1'})));
    await tester.pumpAndSettle();
    expect(find.text('Products page 1'), findsOneWidget);

    unawaited(router.replace(const NamedRoute('ProductsRoute', queryParams: {'page': '2'})));
    await tester.pumpAndSettle();
    expect(router.urlState.url, '/products?page=2');
    expect(find.text('Products page 2'), findsOneWidget);
  });
}
