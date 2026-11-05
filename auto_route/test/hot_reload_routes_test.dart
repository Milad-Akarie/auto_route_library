import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import 'main_router.dart';
import 'router_test_utils.dart';
import 'universal_link_test.dart' show sendPlatformLink;

// flutter/flutter#105553: a route added to the router's list while the app
// runs is not found after a hot reload.
// Show a router whose routes getter has FirstRoute only, add SecondRoute to
// the list, hot reload, then open /second-route, by path and by route.
// SecondRoute should open, as it does after a restart. The same for a child
// route added to a nested router that is already showing.
class _ReloadedRouter extends MainRouter {
  final List<AutoRoute> list = [AutoRoute(page: FirstRoute.page, path: '/')];

  @override
  List<AutoRoute> get routes => list;
}

void main() {
  testWidgets('A route added before a hot reload opens by its path', (
    tester,
  ) async {
    final router = _ReloadedRouter();
    await pumpRouterConfigApp(tester, router.config());
    expectCurrentPage(router, FirstRoute.name);

    router.list.add(AutoRoute(page: SecondRoute.page));
    unawaited(tester.binding.reassembleApplication());
    await tester.pumpAndSettle();

    unawaited(router.navigatePath('/second-route'));
    await tester.pumpAndSettle();
    expectCurrentPage(router, SecondRoute.name);
  });

  testWidgets('A route added before a hot reload opens by its route', (
    tester,
  ) async {
    final router = _ReloadedRouter();
    await pumpRouterConfigApp(tester, router.config());

    router.list.add(AutoRoute(page: SecondRoute.page));
    unawaited(tester.binding.reassembleApplication());
    await tester.pumpAndSettle();

    unawaited(router.push(const SecondRoute()));
    await tester.pumpAndSettle();
    expectCurrentPage(router, SecondRoute.name);
  });

  testWidgets('A link to a route added before a hot reload opens it', (
    tester,
  ) async {
    final router = _ReloadedRouter();
    await pumpRouterConfigApp(tester, router.config());

    router.list.add(AutoRoute(page: SecondRoute.page));
    unawaited(tester.binding.reassembleApplication());
    await tester.pumpAndSettle();

    await sendPlatformLink(tester, '/second-route');
    expectCurrentPage(router, SecondRoute.name);
  });

  testWidgets(
    'A child route added before a hot reload opens in its nested router',
    (tester) async {
      final router = _ReloadedRouter();
      AutoRoute host(List<AutoRoute> children) =>
          .new(path: '/second', page: SecondHostRoute.page, children: children);
      final nested1 = AutoRoute(path: '', page: SecondNested1Route.page);
      router.list.add(host([nested1]));
      await pumpRouterConfigApp(tester, router.config());
      unawaited(router.navigatePath('/second'));
      await tester.pumpAndSettle();
      expectTopPage(router, SecondNested1Route.name);

      router.list.replaceRange(router.list.length - 1, router.list.length, [
        host([
          nested1,
          AutoRoute(path: 'nested2', page: SecondNested2Route.page),
        ]),
      ]);
      unawaited(tester.binding.reassembleApplication());
      await tester.pumpAndSettle();

      final hostRouter = router.innerRouterOf<StackRouter>(
        SecondHostRoute.name,
      )!;
      unawaited(hostRouter.push(const SecondNested2Route()));
      await tester.pumpAndSettle();
      expectTopPage(router, SecondNested2Route.name);

      unawaited(router.navigatePath('/second/nested2'));
      await tester.pumpAndSettle();
      expectTopPage(router, SecondNested2Route.name);
    },
  );
}
