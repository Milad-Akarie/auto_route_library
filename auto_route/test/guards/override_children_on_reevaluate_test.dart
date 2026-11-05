import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// Found while fixing the guard issues, no upstream issue.
// Steps: the router has a reevaluateListenable. DashboardRoute is guarded and
// holds a nested router with HomeRoute (initial) and ProfileRoute. Open the
// dashboard on ProfileRoute, then fire the listenable; on the re-check the
// guard calls resolver.overrideNext(children: [HomeRoute()]).
// Was: the dashboard still showed ProfileRoute. The re-check added the
// dashboard's page back and navigated its nested router to the children it had
// before the guard ran.
// Should: the dashboard shows HomeRoute, as the guard asked.
// navigate() to the open dashboard had the same cause: its nested router went
// to the children passed to navigate(), not to the guard's.
void main() {
  AutoRouteGuard resetToHome() => .simple((resolver, _) {
    if (resolver.isReevaluating) {
      resolver.overrideNext(children: [const _HomeRoute()]);
    } else {
      resolver.next();
    }
  });

  testWidgets('a guard re-check overriding the children of a nested router opens them', (tester) async {
    final auth = ValueNotifier(0);
    addTearDown(auth.dispose);
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _DashboardRoute.page,
          path: '/',
          guards: [resetToHome()],
          children: [
            AutoRoute(page: _HomeRoute.page, path: '', initial: true),
            AutoRoute(page: _ProfileRoute.page, path: 'profile'),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router, initialLink: '/profile', reevaluationNotifier: auth);
    expect(find.text(_ProfileRoute.name), findsOneWidget);

    auth.value++;
    await tester.pumpAndSettle();

    expect(router.topRoute.name, _HomeRoute.name);
    expect(find.text(_HomeRoute.name), findsOneWidget);
    expect(router.urlState.url, '/');
  });

  testWidgets('a guard re-check overriding the children of a tabs router opens that tab', (tester) async {
    final auth = ValueNotifier(0);
    addTearDown(auth.dispose);
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _DashboardTabsRoute.page,
          path: '/',
          guards: [resetToHome()],
          children: [
            AutoRoute(page: _HomeRoute.page, path: '', initial: true),
            AutoRoute(page: _ProfileRoute.page, path: 'profile'),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router, initialLink: '/profile', reevaluationNotifier: auth);
    expect(router.topRoute.name, _ProfileRoute.name);

    auth.value++;
    await tester.pumpAndSettle();

    expect(router.innerRouterOf<TabsRouter>(_DashboardTabsRoute.name)!.activeIndex, 0);
    expect(router.topRoute.name, _HomeRoute.name);
    expect(find.text(_HomeRoute.name), findsOneWidget);
    expect(router.urlState.url, '/');
  });

  testWidgets('navigate() to an open page whose guard overrides its children opens them', (tester) async {
    var reset = false;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _DashboardRoute.page,
          path: '/',
          guards: [
            AutoRouteGuard.simple((resolver, _) {
              if (reset) {
                resolver.overrideNext(children: [const _HomeRoute()]);
              } else {
                resolver.next();
              }
            }),
          ],
          children: [
            AutoRoute(page: _HomeRoute.page, path: '', initial: true),
            AutoRoute(page: _ProfileRoute.page, path: 'profile'),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    expect(router.topRoute.name, _HomeRoute.name);

    reset = true;
    unawaited(router.navigate(const _DashboardRoute(children: [_ProfileRoute()])));
    await tester.pumpAndSettle();

    expect(
      router.topRoute.name,
      _HomeRoute.name,
      reason: 'after router.navigate(const _DashboardRoute(children: [_Profil',
    );
    expect(find.text(_HomeRoute.name), findsOneWidget);
    expect(router.urlState.url, '/');
  });
}

class _DashboardRoute extends PageRouteInfo<void> {
  const new({required List<PageRouteInfo> children}) : super(name, initialChildren: children);

  static const String name = '_DashboardRoute';
  static final PageInfo page = PageInfo(name, builder: (_) => const AutoRouter());
}

class _DashboardTabsRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_DashboardTabsRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const AutoTabsRouter(routes: [_HomeRoute(), _ProfileRoute()]),
  );
}

class _HomeRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_HomeRoute';
  static final PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
}

class _ProfileRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_ProfileRoute';
  static final PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
}
