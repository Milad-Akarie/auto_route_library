import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/cart_router.dart';

// An enum query parameter is read and written by its name.
// https://github.com/Milad-Akarie/auto_route_library/issues/2148
// Headless tests: auto_route/test/enum_query_param/enum_query_param_test.dart
// The router and its page are in support/cart_router.dart, with the router
// generated next to it.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: open the app at the deep link /cart?type=rm.
  // Should: the cart page shows the enum value rm, without the "String is
  // not a subtype of MfUserCartTypes?" type error.
  testWidgets('A deep link reads an enum query parameter by its name', (tester) async {
    final router = CartRouter();
    await pumpRouterApp(tester, router, initialLink: '/cart?type=rm');
    expect(tester.takeException(), isNull);
    expect(router.current.name, MfUserCartRoute.name);
    expect(find.text('Cart rm'), findsOneWidget);
  });

  // Steps: push the cart route with the enum value mf.
  // Should: the url carries type=mf, the form the deep link uses.
  testWidgets('Pushing the route writes the enum by its name in the url', (tester) async {
    final router = CartRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push(MfUserCartRoute(userCartType: .mf)));
    await tester.pumpAndSettle();
    expect(find.text('Cart mf'), findsOneWidget);
    expect(router.urlState.url, '/cart?type=mf');
    await expectBrowserUrl('/cart?type=mf');
  });
}
