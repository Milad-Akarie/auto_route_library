import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#146517: a modal bottom sheet route replaced by another one.
// Steps: push sheet A (a CustomRoute whose customRouteBuilder is a
// ModalBottomSheetRoute), then replace() it with sheet B.
// Should: sheet B shows and A is gone.
void main() {
  testWidgets('replace() swaps one modal bottom sheet route for another', (
    tester,
  ) async {
    PageInfo sheet(String name) =>
        .new(name, builder: (_) => SizedBox(height: 120, child: Text(name)));
    ModalBottomSheetRoute<T> customRouteBuilder<T>(
      BuildContext _,
      Widget child,
      AutoRoutePage<T> page,
    ) => .new(settings: page, builder: (_) => child, isScrollControlled: false);

    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HomeRoute',
            builder: (_) => const Scaffold(body: Text('HomeRoute')),
          ),
        ),
        CustomRoute(
          path: '/a',
          page: sheet('SheetA'),
          customRouteBuilder: customRouteBuilder,
        ),
        CustomRoute(
          path: '/b',
          page: sheet('SheetB'),
          customRouteBuilder: customRouteBuilder,
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.push(const NamedRoute('SheetA')));
    await tester.pumpAndSettle();
    expect(find.text('SheetA'), findsOneWidget);

    unawaited(router.replace(const NamedRoute('SheetB')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('SheetB'), findsOneWidget);
    expect(find.text('SheetA'), findsNothing);
  });
}
