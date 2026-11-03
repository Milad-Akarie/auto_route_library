import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// A PopScope on a nested router's page blocks back, as in a flat route.
// https://github.com/Milad-Akarie/auto_route_library/issues/2023
// Headless test: auto_route/test/nested_router/pop_scope_first_page_test.dart
//
// Setup: a host page with an app bar and a nested router, an AutoRouter or
// an AutoRouter.declarative, whose one page is wrapped in
// PopScope(canPop: false).
// Steps: push the host, then go back: system back, the app bar's back
// button, or the iOS edge swipe (run with the iOS page transitions on every
// platform). Then show the host as the app's first page and press system
// back twice; on Android that goes through the activity, which Android calls only
// while Flutter says it handles back (see systemBack).
// Happened with the declarative router: the swipe popped the host past the
// PopScope, and on Android back closed the app.
// Should: the host and its page stay, and PopScope hears of each back the
// swipe doesn't block.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final routers = <String, Widget Function()>{
    'AutoRouter': () => const AutoRouter(),
    'AutoRouter.declarative': () => AutoRouter.declarative(routes: (_) => [const _GuardedRoute()]),
  };

  for (final MapEntry(key: kind, value: nestedRouter) in routers.entries) {
    group('in an $kind', () {
      late RootStackRouter router;
      setUp(() {
        _popAttempts = 0;
        _nestedRouter = nestedRouter;
        router = RootStackRouter.build(
          routes: [
            AutoRoute(page: FirstRoute.page, path: '/'),
            AutoRoute(
              page: _HostRoute.page,
              path: '/host',
              children: [AutoRoute(page: _GuardedRoute.page, path: '')],
            ),
          ],
        );
      });

      Future<void> openHost(WidgetTester tester, {ThemeData? theme}) async {
        await pumpRouterApp(tester, router, theme: theme);
        unawaited(router.push(const _HostRoute()));
        await tester.pumpAndSettle();
        expectTopPage(router, _GuardedRoute.name);
      }

      void expectHostStays() {
        expect(router.stack.map((page) => page.name), [FirstRoute.name, _HostRoute.name]);
        expectTopPage(router, _GuardedRoute.name);
      }

      Future<void> tapAppBarBack(WidgetTester tester) async {
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }

      final backs = <String, Future<void> Function(WidgetTester)>{
        'system back': systemBack,
        'the app bar back button': tapAppBarBack,
      };

      for (final MapEntry(key: name, value: back) in backs.entries) {
        testWidgets('$name keeps the host when its page has a PopScope', (tester) async {
          await openHost(tester);

          await back(tester);
          expectHostStays();
          expect(_popAttempts, 1);

          await back(tester);
          expectHostStays();
          expect(_popAttempts, 2);
        });
      }

      testWidgets('the iOS back swipe keeps the host when its page has a PopScope', (tester) async {
        await openHost(tester, theme: ThemeData(platform: TargetPlatform.iOS));

        await swipeBack(tester);

        expectHostStays();
      });

      testWidgets('system back on the first page keeps the app open and the page', (tester) async {
        router = RootStackRouter.build(
          routes: [
            AutoRoute(
              page: _HostRoute.page,
              path: '/',
              children: [AutoRoute(page: _GuardedRoute.page, path: '')],
            ),
          ],
        );
        await pumpRouterApp(tester, router);
        expectTopPage(router, _GuardedRoute.name);

        // Twice, as a comment on the issue reports the second back closing the app.
        for (var attempt = 1; attempt <= 2; attempt++) {
          await systemBack(tester);
          expectTopPage(router, _GuardedRoute.name);
          expect(_popAttempts, attempt);
        }
      });
    });
  }
}

var _popAttempts = 0;
late Widget Function() _nestedRouter;

class _HostRoute extends PageRouteInfo<void> {
  const _HostRoute() : super(name);

  static const String name = 'HostRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(
      appBar: AppBar(leading: const AutoLeadingButton()),
      body: _nestedRouter(),
    ),
  );
}

class _GuardedRoute extends PageRouteInfo<void> {
  const _GuardedRoute() : super(name);

  static const String name = 'GuardedRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _popAttempts++;
      },
      child: const Text(name),
    ),
  );
}
