import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _BootRoute.page, initial: true),
        AutoRoute(
          page: _DashboardRoute.page,
          children: [
            AutoRoute(page: _MetricsRoute.page, initial: true),
            AutoRoute(
              page: const EmptyShellRoute(_kUsersShell),
              children: [
                AutoRoute(page: _UsersRoute.page, initial: true),
                AutoRoute(page: _UserRoute.page),
              ],
            ),
          ],
        ),
      ],
    );
  });

  Future<StackRouter> openDashboard(WidgetTester tester) async {
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.replaceAll([const _DashboardRoute()]));
    await tester.pumpAndSettle();
    expectTopPage(router, _MetricsRoute.name);
    return router.innerRouterOf<StackRouter>(_DashboardRoute.name)!;
  }

  // https://github.com/Milad-Akarie/auto_route_library/issues/2214
  // On the dashboard, which shows MetricsRoute, call
  // innerRouterOf(DashboardRoute).replaceAll([UsersRoute(), UserRoute(userId: 1)]).
  // Both routes live in the 'UsersSellRoute' shell, which isn't open yet. They
  // should open together in one shell, so UserRoute has a back button to
  // UsersRoute, not each in its own copy of the shell.
  testWidgets('replaceAll with two routes of a nested router opens both in one nested router', (tester) async {
    final dashboard = await openDashboard(tester);

    unawaited(dashboard.replaceAll([const _UsersRoute(), const _UserRoute(userId: 1)]));
    await tester.pumpAndSettle();
    expect(dashboard.stack.map((p) => p.name), [_kUsersShell]);
    final shell = dashboard.innerRouterOf<StackRouter>(_kUsersShell)!;
    expect(shell.stack.map((p) => p.name), [_UsersRoute.name, _UserRoute.name]);
    expectTopPage(router, _UserRoute.name);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expectTopPage(router, _UsersRoute.name);
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/2214
  // The reporter's comment: pushAll with the same routes does the same.
  testWidgets('pushAll with two routes of a nested router opens both in one nested router', (tester) async {
    final dashboard = await openDashboard(tester);

    unawaited(dashboard.pushAll([const _UsersRoute(), const _UserRoute(userId: 1)]));
    await tester.pumpAndSettle();
    expect(dashboard.stack.map((p) => p.name), [_MetricsRoute.name, _kUsersShell]);
    final shell = dashboard.innerRouterOf<StackRouter>(_kUsersShell)!;
    expect(shell.stack.map((p) => p.name), [_UsersRoute.name, _UserRoute.name]);
    expectTopPage(router, _UserRoute.name);
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/2214
  // Routes that name their parent explicitly still open one parent each.
  testWidgets('pushAll keeps a parent the caller names for each route', (tester) async {
    final dashboard = await openDashboard(tester);

    unawaited(
      dashboard.pushAll([
        const PageRouteInfo(_kUsersShell, initialChildren: [_UsersRoute()]),
        const PageRouteInfo(_kUsersShell, initialChildren: [_UserRoute(userId: 1)]),
      ]),
    );
    await tester.pumpAndSettle();
    expect(dashboard.stack.map((p) => p.name), [_MetricsRoute.name, _kUsersShell, _kUsersShell]);
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/2214
  // Only a stack opens listed routes in one nested router. A tabs router whose
  // routes are [UsersRoute(), UserRoute()] shows two tabs, each in its own
  // copy of the shell.
  testWidgets('a tabs router keeps two tabs of one nested router as two tabs', (tester) async {
    final tabsApp = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _TabsRoute.page,
          initial: true,
          children: [
            AutoRoute(
              page: const EmptyShellRoute(_kUsersShell),
              children: [
                AutoRoute(page: _UsersRoute.page, initial: true),
                AutoRoute(page: _UserRoute.page),
              ],
            ),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, tabsApp.config());
    final tabs = tabsApp.innerRouterOf<TabsRouter>(_TabsRoute.name)!;
    expect(tabs.stack.map((p) => p.name), [_kUsersShell, _kUsersShell]);
    expect(find.text(_UsersRoute.name), findsOneWidget);

    tabs.setActiveIndex(1);
    await tester.pumpAndSettle();
    expect(find.text(_UserRoute.name), findsOneWidget);
  });
}

const _kUsersShell = 'UsersSellRoute';

class _BootRoute extends PageRouteInfo<void> {
  const _BootRoute() : super(name);

  static const String name = 'BootRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
}

class _DashboardRoute extends PageRouteInfo<void> {
  const _DashboardRoute() : super(name);

  static const String name = 'DashboardRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: AutoRouter()));
}

class _TabsRoute extends PageRouteInfo<void> {
  const _TabsRoute() : super(name);

  static const String name = 'TabsRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const AutoTabsRouter(routes: [_UsersRoute(), _UserRoute(userId: 1)]),
  );
}

class _MetricsRoute extends PageRouteInfo<void> {
  const _MetricsRoute() : super(name);

  static const String name = 'MetricsRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
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
