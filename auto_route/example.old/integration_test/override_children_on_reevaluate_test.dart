import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// The children a guard sets with resolver.overrideNext(children: ...) open,
// on a guard re-check and on navigate() to the open page.
// Found while fixing the guard issues, no upstream issue.
// Headless test:
// auto_route/test/guards/override_children_on_reevaluate_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('override children on reevaluate', () {
    List<AutoRoute> dashboardChildren() => [
      AutoRoute(page: _HomeRoute.page, path: '', initial: true),
      AutoRoute(page: _ProfileRoute.page, path: 'profile'),
    ];

    AutoRouteGuard resetToHome() => .simple((resolver, _) {
      if (resolver.isReevaluating) {
        resolver.overrideNext(children: [const _HomeRoute()]);
      } else {
        resolver.next();
      }
    });

    // Steps: open the guarded dashboard on '/profile' with reevaluateListenable
    // set, then fire the listenable; the guard's re-check overrides the
    // dashboard's children with HomeRoute.
    // Should: the dashboard's nested router shows HomeRoute and the url is '/'.
    testWidgets(
      'a guard re-check overriding the children of a nested router opens them',
      (tester) async {
        final auth = ValueNotifier(0);
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(
              page: _DashboardRoute.page,
              path: '/',
              guards: [resetToHome()],
              children: dashboardChildren(),
            ),
          ],
        );
        await pumpRouterConfigApp(
          tester,
          router.config(
            reevaluateListenable: auth,
            deepLinkBuilder: (link) =>
                link.initial ? const DeepLink.path('/profile') : link,
          ),
        );
        expectTopPage(router, _ProfileRoute.name);

        auth.value++;
        await tester.pumpAndSettle();

        expectTopPage(router, _HomeRoute.name);
        await expectBrowserUrl('/');
      },
    );

    // Steps: the same, with the dashboard holding an AutoTabsRouter.
    // Should: the dashboard switches to the HomeRoute tab and the url is '/'.
    testWidgets(
      'a guard re-check overriding the children of a tabs router opens that '
      'tab',
      (tester) async {
        final auth = ValueNotifier(0);
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(
              page: _DashboardTabsRoute.page,
              path: '/',
              guards: [resetToHome()],
              children: dashboardChildren(),
            ),
          ],
        );
        await pumpRouterConfigApp(
          tester,
          router.config(
            reevaluateListenable: auth,
            deepLinkBuilder: (link) =>
                link.initial ? const DeepLink.path('/profile') : link,
          ),
        );
        expectTopPage(router, _ProfileRoute.name);

        auth.value++;
        await tester.pumpAndSettle();

        expect(
          router
              .innerRouterOf<TabsRouter>(_DashboardTabsRoute.name)!
              .activeIndex,
          0,
        );
        expectTopPage(router, _HomeRoute.name);
        await expectBrowserUrl('/');
      },
    );

    // Steps: open the dashboard on HomeRoute, then navigate() to it with
    // ProfileRoute as its child; its guard overrides the children with
    // HomeRoute.
    // Should: the dashboard still shows HomeRoute and the url is '/'.
    testWidgets(
      'navigate() to an open page whose guard overrides its children opens '
      'them',
      (tester) async {
        final reset = ValueNotifier(false);
        addTearDown(reset.dispose);
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(
              page: _DashboardRoute.page,
              path: '/',
              guards: [
                AutoRouteGuard.simple((resolver, _) {
                  if (reset.value) {
                    resolver.overrideNext(children: [const _HomeRoute()]);
                  } else {
                    resolver.next();
                  }
                }),
              ],
              children: dashboardChildren(),
            ),
          ],
        );
        await pumpRouterAppWithConfig(tester, router);
        expectTopPage(router, _HomeRoute.name);

        reset.value = true;
        unawaited(
          router.navigate(const _DashboardRoute(children: [_ProfileRoute()])),
        );
        await tester.pumpAndSettle();

        expectTopPage(router, _HomeRoute.name);
        await expectBrowserUrl('/');
      },
    );
  });
}

class _DashboardRoute extends PageRouteInfo<void> {
  const new({List<PageRouteInfo>? children})
    : super(name, initialChildren: children);

  static const String name = '_DashboardRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const AutoRouter());
}

class _DashboardTabsRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_DashboardTabsRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) =>
        const AutoTabsRouter(routes: [_HomeRoute(), _ProfileRoute()]),
  );
}

class _HomeRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_HomeRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: Text(name)),
  );
}

class _ProfileRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_ProfileRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: Text(name)),
  );
}
