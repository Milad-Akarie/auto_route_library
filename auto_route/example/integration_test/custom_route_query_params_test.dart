import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A customRouteBuilder page shows the new query params after replace().
// Regression of https://github.com/Milad-Akarie/auto_route_library/issues/1857
// Headless test: auto_route/test/custom_route_builder_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: ProductsRoute is a CustomRoute whose customRouteBuilder wraps the
  // child in a SelectionArea. Push it with page=1, then replace() it with page=2.
  // Should: the page shows page 2.
  testWidgets('a customRouteBuilder page shows the new query params after replace()', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
        ),
        CustomRoute<dynamic>(
          path: '/products',
          page: PageInfo(
            'ProductsRoute',
            builder: (data) =>
                Scaffold(body: SafeArea(child: Text('Products page ${data.queryParams.optString('page')}'))),
          ),
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
    expect(find.text('Products page 2'), findsOneWidget);
    await expectBrowserUrl('/products?page=2');
  });
}
