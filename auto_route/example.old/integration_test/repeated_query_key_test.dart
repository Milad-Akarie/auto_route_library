import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A page reading optString builds from a deep link that repeats the key.
// Found by strict-casts while moving the package to very_good_analysis; no
// upstream issue.
// Headless test: auto_route/test/repeated_query_key_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('repeated query key', () {
    // Steps: ProductsRoute shows `queryParams.optString('tag')`. Open
    // /products?tag=red&tag=blue.
    // Should: the page builds and shows the last value, blue.
    testWidgets(
      'a page reading optString builds from a deep link that repeats the key',
      (tester) async {
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(
              path: '/',
              page: PageInfo(
                'HomeRoute',
                builder: (_) => const Text('HomeRoute'),
              ),
            ),
            AutoRoute(
              path: '/products',
              page: PageInfo(
                'ProductsRoute',
                builder: (data) => Scaffold(
                  body: SafeArea(
                    child: Text(
                      'Tag ${data.queryParams.optString('tag') ?? 'null'}',
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
        await pumpRouterApp(tester, router);
        unawaited(router.navigatePath('/products?tag=red&tag=blue'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Tag blue'), findsOneWidget);
      },
    );
  });
}
