import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// popUntil, pushAndPopUntil and popAndPushAll called again before the previous
// navigation settles don't throw "Bad state: Future already completed".
// https://github.com/Milad-Akarie/auto_route_library/issues/1005
// Headless test: auto_route/test/simple_router/rapid_pops_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('rapid pops', () {
    late RootStackRouter router;
    setUp(() {
      router = RootStackRouter.build(
        routes: [
          AutoRoute(page: _page('MainRoute'), path: '/', initial: true),
          for (final name in [
            'ShoppingCartRoute',
            'MyDeliveriesRoute',
            'SignInRoute',
            'VerifyRoute',
            'FirstRoute',
            'SecondRoute',
          ])
            AutoRoute(page: _page(name), path: '/$name'),
        ],
      );
    });

    List<String?> stackNames() => router.stack.map((p) => p.name).toList();

    // Steps: call pushAndPopUntil(SignInRoute) and pushAndPopUntil(VerifyRoute)
    // at once, then pushAndPopUntil(MainRoute) while VerifyRoute animates in.
    // Should: no error; the stack is [VerifyRoute], then [MainRoute]. The
    // second call removes SignInRoute too, though it has not shown yet (#1797).
    testWidgets('pushAndPopUntil twice in a row, then again while animating', (
      tester,
    ) async {
      await pumpRouterApp(tester, router);
      unawaited(router.push(const PageRouteInfo('ShoppingCartRoute')));
      await tester.pumpAndSettle();

      unawaited(
        router.pushAndPopUntil(
          const PageRouteInfo('SignInRoute'),
          predicate: (_) => false,
        ),
      );
      unawaited(
        router.pushAndPopUntil(
          const PageRouteInfo('VerifyRoute'),
          predicate: (_) => false,
        ),
      );
      await tester.pumpAndSettle();
      final earlier1 = tester.takeException();
      expect(stackNames(), ['VerifyRoute']);

      unawaited(
        router.pushAndPopUntil(
          const PageRouteInfo('ShoppingCartRoute'),
          predicate: (_) => false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      unawaited(
        router.pushAndPopUntil(
          const PageRouteInfo('MainRoute'),
          predicate: (_) => false,
        ),
      );
      await tester.pumpAndSettle();
      expect((earlier1, tester.takeException()), (null, null));
      expect(stackNames(), ['MainRoute']);
    });

    // Steps: popUntilRouteWithName(MainRoute), push MyDeliveriesRoute, and
    // popUntilRouteWithName(MainRoute) again before the push settles; then
    // push two pages and call popUntilRoot twice at once.
    // Should: no error, and MainRoute is the only page each time.
    testWidgets(
      'popUntilRouteWithName and popUntilRoot again before the stack settles',
      (tester) async {
        await pumpRouterApp(tester, router);
        unawaited(router.push(const PageRouteInfo('ShoppingCartRoute')));
        await tester.pumpAndSettle();

        router.popUntilRouteWithName('MainRoute');
        unawaited(router.push(const PageRouteInfo('MyDeliveriesRoute')));
        await tester.pump(const Duration(milliseconds: 50));
        router.popUntilRouteWithName('MainRoute');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(stackNames(), ['MainRoute']);

        unawaited(router.push(const PageRouteInfo('ShoppingCartRoute')));
        unawaited(router.push(const PageRouteInfo('MyDeliveriesRoute')));
        await tester.pump();
        for (var pops = 0; pops < 2; pops++) {
          router.popUntilRoot();
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(stackNames(), ['MainRoute']);
      },
    );

    // Steps: push a page that, 150ms later while still animating in, calls
    // popAndPushAll([FirstRoute(), SecondRoute()]), as the linked demo app
    // does.
    // Should: no error; the stack is [MainRoute, FirstRoute, SecondRoute].
    testWidgets('popAndPushAll while the page it pops animates in', (
      tester,
    ) async {
      await pumpRouterApp(tester, router);
      unawaited(router.push(const PageRouteInfo('ShoppingCartRoute')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      unawaited(
        router.popAndPushAll(const [
          PageRouteInfo('FirstRoute'),
          PageRouteInfo('SecondRoute'),
        ]),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(stackNames(), ['MainRoute', 'FirstRoute', 'SecondRoute']);
    });
  });
}

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(appBar: AppBar(), body: Text(name)),
);
