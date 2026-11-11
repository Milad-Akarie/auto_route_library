import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../router_test_utils.dart';
import 'cart_router.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/2148
  // A page takes an enum as a query parameter, and the app opens the deep
  // link /cart?type=rm. The generated route read the parameter as it came,
  // the string 'rm', and threw a type error (String is not
  // MfUserCartTypes?). It should read the enum by its name. The router and
  // its page are in cart_router.dart, with the router generated next to it.
  testWidgets('A deep link reads an enum query parameter by its name', (
    tester,
  ) async {
    final router = CartRouter();
    await pumpRouterApp(tester, router, initialLink: '/cart?type=rm');
    expect(tester.takeException(), isNull);
    expect(router.current.name, MfUserCartRoute.name);
    expect(find.text('Cart rm'), findsOneWidget);
  });

  testWidgets('A name the enum does not have reads as null', (tester) async {
    final router = CartRouter();
    await pumpRouterApp(tester, router, initialLink: '/cart?type=unknown');
    expect(tester.takeException(), isNull);
    expect(find.text('Cart null'), findsOneWidget);
  });

  // Pushing the route puts the enum's name in the url, the same form the
  // deep link uses, not `MfUserCartTypes.rm`.
  testWidgets('Pushing the route writes the enum by its name in the url', (
    tester,
  ) async {
    final router = CartRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push(MfUserCartRoute(userCartType: .mf)));
    await tester.pumpAndSettle();
    expect(find.text('Cart mf'), findsOneWidget);
    expect(router.urlState.url, '/cart?type=mf');
  });
}
