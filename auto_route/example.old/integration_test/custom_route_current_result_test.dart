import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A page whose route sets currentResult completes its push with it when the
// back swipe or system back pops it.
// flutter/flutter#171130
// Headless test: auto_route/test/custom_route_current_result_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('custom route current result', () {
    late RootStackRouter router;
    setUp(() {
      router = RootStackRouter.build(
        routes: [
          AutoRoute(
            page: PageInfo(
              'Home',
              builder: (_) =>
                  const Scaffold(body: SafeArea(child: Text('Home'))),
            ),
            path: '/',
            initial: true,
          ),
          CustomRoute(
            page: PageInfo(
              'Details',
              builder: (_) =>
                  const Scaffold(body: SafeArea(child: Text('Details'))),
            ),
            path: '/details',
            customRouteBuilder: <T>(context, child, page) => _ResultRoute<T>(
              settings: page,
              result: 'picked' as T,
              builder: (_) => child,
            ),
          ),
        ],
      );
    });

    final backs = {'the iOS back swipe': swipeBack, 'system back': systemBack};

    // Steps: Details is a CustomRoute whose customRouteBuilder returns a
    // CupertinoPageRoute reporting currentResult 'picked'. Push it, then go
    // back by the iOS swipe or system back.
    // Should: the push completes with 'picked', as Navigator.push does.
    for (final MapEntry(key: name, value: back) in backs.entries) {
      testWidgets("$name completes the push with the route's currentResult", (
        tester,
      ) async {
        await pumpRouterApp(tester, router);
        Object? result = 'unset';
        unawaited(
          router
              .push<String>(const PageRouteInfo('Details'))
              .then((value) => result = value),
        );
        await tester.pumpAndSettle();

        await back(tester);

        expectCurrentPage(router, 'Home');
        expect(result, 'picked');
      });
    }
  });
}

class _ResultRoute<T> extends CupertinoPageRoute<T> {
  new({
    required super.builder,
    required super.settings,
    required this.result,
  });

  final T result;

  @override
  T? get currentResult => result;
}
