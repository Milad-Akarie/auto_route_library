import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _SplashRoute.page, initial: true),
        AutoRoute(
          page: _AppRouterRoute.page,
          children: [
            AutoRoute(page: _HomeRoute.page, initial: true),
            AutoRoute(page: _OtherRoute.page),
            AutoRoute(page: _TestRoute.page),
          ],
        ),
      ],
    );
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1948
  // The app's pages live in a nested router named 'app_router', opened over a
  // splash page. From its only page, call
  // innerRouterOf('app_router').popAndPushAll([TestRoute()]).
  // TestRoute should take the place of the page, inside the nested router,
  // instead of the pop closing the page that holds the nested router.
  testWidgets('popAndPushAll from the only page of a nested router replaces that page', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    router.push(const _AppRouterRoute());
    await tester.pumpAndSettle();
    final appRouter = router.innerRouterOf<StackRouter>(_AppRouterRoute.name)!;
    expect(appRouter.stack.map((p) => p.name), [_HomeRoute.name]);

    appRouter.popAndPushAll([const _TestRoute()]);
    await tester.pumpAndSettle();
    expect(router.stack.map((p) => p.name), [_SplashRoute.name, _AppRouterRoute.name]);
    expect(appRouter.stack.map((p) => p.name), [_TestRoute.name]);
    expect(find.text('Test'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1948
  // With more than one page in the nested router, popAndPushAll pops the top
  // page and pushes the routes in its place.
  testWidgets('popAndPushAll pops the top page and pushes the routes in its place', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    router.push(const _AppRouterRoute());
    await tester.pumpAndSettle();
    final appRouter = router.innerRouterOf<StackRouter>(_AppRouterRoute.name)!;
    appRouter.push(const _OtherRoute());
    await tester.pumpAndSettle();

    appRouter.popAndPushAll([const _TestRoute()]);
    await tester.pumpAndSettle();
    expect(appRouter.stack.map((p) => p.name), [_HomeRoute.name, _TestRoute.name]);
    expect(find.text('Test'), findsOneWidget);
  });
}

class _SplashRoute extends PageRouteInfo<void> {
  const _SplashRoute() : super(name);

  static const String name = 'SplashRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text('Splash')));
}

class _AppRouterRoute extends PageRouteInfo<void> {
  const _AppRouterRoute() : super(name);

  static const String name = 'app_router';
  static PageInfo page = PageInfo(name, builder: (_) => const AutoRouter());
}

class _HomeRoute extends PageRouteInfo<void> {
  const _HomeRoute() : super(name);

  static const String name = 'HomeRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text('Home')));
}

class _OtherRoute extends PageRouteInfo<void> {
  const _OtherRoute() : super(name);

  static const String name = 'OtherRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text('Other')));
}

class _TestRoute extends PageRouteInfo<void> {
  const _TestRoute() : super(name);

  static const String name = 'TestRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text('Test')));
}
