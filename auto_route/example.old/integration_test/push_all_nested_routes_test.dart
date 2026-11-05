import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// replaceAll with routes of a nested router that isn't open opens them in one nested router.
// https://github.com/Milad-Akarie/auto_route_library/issues/2214
// Headless test: auto_route/test/nested_router/push_all_nested_routes_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _BootRoute.page, path: '/', initial: true),
        AutoRoute(
          page: _DashboardRoute.page,
          path: '/dashboard',
          children: [
            AutoRoute(page: _MetricsRoute.page, path: '', initial: true),
            AutoRoute(
              page: const EmptyShellRoute(_usersShell),
              path: 'users',
              children: [
                AutoRoute(page: _UsersRoute.page, path: '', initial: true),
                AutoRoute(page: _UserRoute.page, path: 'user'),
              ],
            ),
          ],
        ),
      ],
    );
  });

  // Steps: open the dashboard, which shows MetricsRoute, then call
  // innerRouterOf(DashboardRoute).replaceAll([UsersRoute(), UserRoute(userId: 1)]),
  // then tap UserRoute's back button.
  // Should: both routes open in one 'UsersSellRoute' shell, UserRoute on top
  // with a back button, and back shows UsersRoute.
  testWidgets('replaceAll with two routes of a nested router opens both in one nested router', (tester) async {
    await pumpRouterApp(tester, router);
    unawaited(router.replaceAll([const _DashboardRoute()]));
    await tester.pumpAndSettle();
    final dashboard = router.innerRouterOf<StackRouter>(_DashboardRoute.name)!;

    unawaited(dashboard.replaceAll([const _UsersRoute(), const _UserRoute(userId: 1)]));
    await tester.pumpAndSettle();
    expect(dashboard.stack.map((p) => p.name), [_usersShell]);
    final shell = dashboard.innerRouterOf<StackRouter>(_usersShell)!;
    expect(shell.stack.map((p) => p.name), [_UsersRoute.name, _UserRoute.name]);
    expectTopPage(router, _UserRoute.name);
    await expectBrowserUrl('/dashboard/users/user');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expectTopPage(router, _UsersRoute.name);
  });
}

const _usersShell = 'UsersSellRoute';

class _BootRoute extends PageRouteInfo<void> {
  const _BootRoute() : super(name);

  static const String name = 'BootRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: SafeArea(child: Text(name))),
  );
}

class _DashboardRoute extends PageRouteInfo<void> {
  const _DashboardRoute() : super(name);

  static const String name = 'DashboardRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: AutoRouter()));
}

class _MetricsRoute extends PageRouteInfo<void> {
  const _MetricsRoute() : super(name);

  static const String name = 'MetricsRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: SafeArea(child: Text(name))),
  );
}

class _UsersRoute extends PageRouteInfo<void> {
  const _UsersRoute() : super(name);

  static const String name = 'UsersRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(appBar: AppBar(), body: const Text(name)),
  );
}

class _UserRoute extends PageRouteInfo<int> {
  const _UserRoute({required int userId}) : super(name, args: userId);

  static const String name = 'UserRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(appBar: AppBar(), body: const Text(name)),
  );
}
