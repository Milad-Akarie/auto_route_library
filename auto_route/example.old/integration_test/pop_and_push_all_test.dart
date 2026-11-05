import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// popAndPushAll from the only page of a nested router replaces that page.
// https://github.com/Milad-Akarie/auto_route_library/issues/1948
// Headless test: auto_route/test/nested_router/pop_and_push_all_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _SplashRoute.page, path: '/', initial: true),
        AutoRoute(
          page: _AppRouterRoute.page,
          path: '/app',
          children: [
            AutoRoute(page: _HomeRoute.page, path: '', initial: true),
            AutoRoute(page: _TestRoute.page, path: 'test'),
          ],
        ),
      ],
    );
  });

  // Steps: open the nested router 'app_router' over a splash page, then from
  // its only page call
  // innerRouterOf('app_router').popAndPushAll([TestRoute()]).
  // Should: TestRoute replaces the page inside the nested router, and the
  // page holding the nested router stays.
  testWidgets(
    'popAndPushAll from the only page of a nested router replaces that page',
    (tester) async {
      await pumpRouterApp(tester, router);
      unawaited(router.push(const _AppRouterRoute()));
      await tester.pumpAndSettle();
      final appRouter = router.innerRouterOf<StackRouter>(
        _AppRouterRoute.name,
      )!;

      unawaited(appRouter.popAndPushAll([const _TestRoute()]));
      await tester.pumpAndSettle();
      expect(router.stack.map((p) => p.name), [
        _SplashRoute.name,
        _AppRouterRoute.name,
      ]);
      expect(appRouter.stack.map((p) => p.name), [_TestRoute.name]);
      expect(find.text('Test'), findsOneWidget);
      await expectBrowserUrl('/app/test');
    },
  );
}

class _SplashRoute extends PageRouteInfo<void> {
  const _SplashRoute() : super(name);

  static const String name = 'SplashRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: SafeArea(child: Text('Splash'))),
  );
}

class _AppRouterRoute extends PageRouteInfo<void> {
  const _AppRouterRoute() : super(name);

  static const String name = 'app_router';
  static PageInfo page = PageInfo(name, builder: (_) => const AutoRouter());
}

class _HomeRoute extends PageRouteInfo<void> {
  const _HomeRoute() : super(name);

  static const String name = 'HomeRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: SafeArea(child: Text('Home'))),
  );
}

class _TestRoute extends PageRouteInfo<void> {
  const _TestRoute() : super(name);

  static const String name = 'TestRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: SafeArea(child: Text('Test'))),
  );
}
