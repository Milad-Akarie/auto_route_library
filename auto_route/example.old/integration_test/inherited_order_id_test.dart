import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// navigateTo() a child of an open order keeps its inherited orderId.
// https://github.com/Milad-Akarie/auto_route_library/issues/1827
// Headless test: auto_route/test/nested_router/inherited_order_id_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: under '/orders', open OrderRoute(orderId: 'o-1') from the orders list,
  // then call context.navigateTo(OrderPaymentProofRoute()) from the order's
  // page.
  // Should: the proof page opens under order 'o-1' and reads its inherited
  // 'orderId', not fail to parse it from null.
  testWidgets(
    'navigateTo() a child of an open order keeps its inherited orderId',
    (tester) async {
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
                children: [
                  AutoRoute(
                    page: _OrderPaymentProofRoute.page,
                    path: 'payment-proof',
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router, initialLink: '/orders');
      unawaited(
        tester
            .element(find.text('Orders'))
            .navigateTo(_OrderRoute(orderId: 'o-1')),
      );
      await tester.pumpAndSettle();

      unawaited(
        tester
            .element(find.text('Order o-1'))
            .navigateTo(const _OrderPaymentProofRoute()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Payment proof of o-1'), findsOneWidget);
      expect(router.urlState.url, '/orders/o-1/payment-proof');
      await expectBrowserUrl('/orders/o-1/payment-proof');
    },
  );
}

class _OrdersWrapperRoute extends PageRouteInfo<void> {
  const _OrdersWrapperRoute() : super(pageName);

  static const String pageName = 'OrdersWrapperRoute';
  static PageInfo page = PageInfo(pageName, builder: (_) => const AutoRouter());
}

class _OrdersRoute extends PageRouteInfo<void> {
  const _OrdersRoute() : super(pageName);

  static const String pageName = 'OrdersRoute';
  static PageInfo page = PageInfo(
    pageName,
    builder: (_) => const Text('Orders'),
  );
}

class _OrderRoute extends PageRouteInfo<void> {
  _OrderRoute({required String orderId})
    : super(pageName, rawPathParams: {'orderId': orderId});

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
  const _OrderPaymentProofRoute() : super(pageName);

  static const String pageName = 'OrderPaymentProofRoute';
  static PageInfo page = PageInfo(
    pageName,
    // As generated for a constructor parameter marked @PathParam.inherit().
    builder: (data) => Text(
      'Payment proof of ${data.inheritedPathParams.getString('orderId')}',
    ),
  );
}
