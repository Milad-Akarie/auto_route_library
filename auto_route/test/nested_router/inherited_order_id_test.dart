import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1827
  // Under '/orders', open OrderRoute(orderId: 'o-1') from the orders list,
  // then call context.navigateTo(OrderPaymentProofRoute()) from the order's
  // page. The proof page should open under order 'o-1' and read its inherited
  // 'orderId', not fail to parse it from null.
  testWidgets('navigateTo() a child of an open order keeps its inherited orderId', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _OrdersWrapperRoute.page,
          path: '/orders',
          initial: true,
          children: [
            AutoRoute(page: _OrdersRoute.page, path: '', initial: true),
            AutoRoute(
              page: _OrderRoute.page,
              path: ':orderId',
              children: [AutoRoute(page: _OrderPaymentProofRoute.page, path: 'payment-proof')],
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router, initialLink: '/orders');
    unawaited(tester.element(find.text('Orders')).navigateTo(_OrderRoute(orderId: 'o-1')));
    await tester.pumpAndSettle();

    unawaited(tester.element(find.text('Order o-1')).navigateTo(const _OrderPaymentProofRoute()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Payment proof of o-1'), findsOneWidget);
    expect(router.urlState.url, '/orders/o-1/payment-proof');
  });
}

class _OrdersWrapperRoute extends PageRouteInfo<void> {
  const new() : super(pageName);

  static const String pageName = 'OrdersWrapperRoute';
  static PageInfo page = PageInfo(pageName, builder: (_) => const AutoRouter());
}

class _OrdersRoute extends PageRouteInfo<void> {
  const new() : super(pageName);

  static const String pageName = 'OrdersRoute';
  static PageInfo page = PageInfo(pageName, builder: (_) => const Text('Orders'));
}

class _OrderRoute extends PageRouteInfo<void> {
  new({required String orderId}) : super(pageName, rawPathParams: {'orderId': orderId});

  static const String pageName = 'OrderRoute';
  static PageInfo page = PageInfo(
    pageName,
    // As generated for a constructor parameter marked @pathParam.
    builder: (data) => Column(
      children: [
        Text('Order ${data.inheritedPathParams.getString('orderId')}'),
        const Expanded(child: AutoRouter()),
      ],
    ),
  );
}

class _OrderPaymentProofRoute extends PageRouteInfo<void> {
  const new() : super(pageName);

  static const String pageName = 'OrderPaymentProofRoute';
  static PageInfo page = PageInfo(
    pageName,
    // As generated for a constructor parameter marked @PathParam.inherit().
    builder: (data) => Text('Payment proof of ${data.inheritedPathParams.getString('orderId')}'),
  );
}
