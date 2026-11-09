import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// #1013 (auto_route 2.3.0): pushing the path of a wrapper route whose initial
// child has an empty path ended in a StackOverflowError.
// Setup: '/' is 'HomeRoute'; '/mobile_wallets' is the wrapper 'WrapperRoute'
// with children '' ('WalletsRoute', initial) and 'create' ('CreateRoute').
// Steps: pushPath('/mobile_wallets'); then pushPath('/mobile_wallets') again
// from there; then pushPath('/mobile_wallets/create').
// Should: no exception; the wrapper shows its WalletsRoute, then WalletsRoute is
// pushed again inside the wrapper, then the wrapper shows CreateRoute.
void main() {
  testWidgets('Pushing the path of a wrapper with an empty child works', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(path: '/', initial: true, page: _page('HomeRoute')),
        AutoRoute(
          path: '/mobile_wallets',
          page: PageInfo('WrapperRoute', builder: (_) => const AutoRouter()),
          children: [
            AutoRoute(path: '', initial: true, page: _page('WalletsRoute')),
            AutoRoute(path: 'create', page: _page('CreateRoute')),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);

    final steps = <String>[];
    for (final path in [
      '/mobile_wallets',
      '/mobile_wallets',
      '/mobile_wallets/create',
    ]) {
      unawaited(router.pushPath(path));
      await tester.pumpAndSettle();
      final isClean = tester.takeException() == null;
      final inner = router.innerRouterOf<StackRouter>('WrapperRoute')!;
      steps.add(
        'clean: $isClean, top: ${router.topRoute.name}, '
        'root: ${router.stack.map((page) => page.name)}, '
        'wrapper: ${inner.stack.map((page) => page.name)}',
      );
    }

    // pushPath goes to the deepest router that matches the path, here the
    // wrapper's own, so the second push stacks WalletsRoute inside it.
    String step(String top, String wrapper) =>
        'clean: true, top: $top, root: (HomeRoute, WrapperRoute), '
        'wrapper: ($wrapper)';
    expect(steps, [
      step('WalletsRoute', 'WalletsRoute'),
      step('WalletsRoute', 'WalletsRoute, WalletsRoute'),
      step('CreateRoute', 'WalletsRoute, WalletsRoute, CreateRoute'),
    ]);
  });
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
