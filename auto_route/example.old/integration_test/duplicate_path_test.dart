import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

// Two routes with the same full path make the router fail when the app
// starts, naming both, instead of opening only the first for their url.
// flutter/flutter#190741 asked go_router_builder for the same report.
// Headless tests: auto_route/test/duplicate_path_test.dart
// The router is built here from plain PageInfos; it needs no generated code.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('duplicate path', () {
    PageInfo page(String name) => .new(name, builder: (_) => Text(name));

    // Steps: start an app whose routes hold /shop with the child cart, and
    // /shop/cart.
    // Should: the app fails at once with an error naming
    // CartRoute, OtherCartRoute and the path.
    testWidgets(
      'An app with two routes for one path fails to start, naming both',
      (tester) async {
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(page: page('HomeRoute'), path: '/'),
            AutoRoute(
              page: page('ShopRoute'),
              path: '/shop',
              children: [AutoRoute(page: page('CartRoute'), path: 'cart')],
            ),
            AutoRoute(page: page('OtherCartRoute'), path: '/shop/cart'),
          ],
        );
        addTearDown(router.dispose);
        Object? error;
        try {
          await tester.pumpWidget(
            MaterialApp.router(routerConfig: router.config()),
          );
          // The router reports a route list it can't use with a FlutterError.
          // ignore: avoid_catching_errors
        } on FlutterError catch (e) {
          error = e;
        }
        expect(
          error?.toString(),
          'CartRoute and OtherCartRoute have the same path, /shop/cart, so a link to it opens only CartRoute. '
          'Give one of them another path.',
        );
      },
    );
  });
}
