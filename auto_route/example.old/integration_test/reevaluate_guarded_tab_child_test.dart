import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Logging out closes a guarded child inside a tab.
// https://github.com/Milad-Akarie/auto_route_library/issues/1740
// Headless test:
// auto_route/test/reevaluatable_router/reevaluate_nested_tab_guard_test.dart
//
// Setup, as in the report: a home page with an AutoTabsRouter whose first tab,
// MainRoute, has the children MainPage and AuthRequiredPage; AuthRequiredPage
// has a guard that lets in only a logged-in user. The router gets
// reevaluateListenable: the auth state.
// Steps: log in, open AuthRequiredPage inside the first tab, log out.
// Reported: AuthRequiredPage stayed on screen; the url stayed its own.
// Should: AuthRequiredPage closes, the tab shows MainPage, and the url is
// MainPage's.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('reevaluate guarded tab child', () {
    testWidgets('logging out closes the guarded child and updates the url', (
      tester,
    ) async {
      final isLoggedIn = ValueNotifier(true);
      addTearDown(isLoggedIn.dispose);
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            page: PageInfo('HomeRoute', builder: (_) => const AutoTabsRouter()),
            path: '/',
            children: [
              AutoRoute(
                page: PageInfo('MainRoute', builder: (_) => const AutoRouter()),
                initial: true,
                children: [
                  AutoRoute(page: _page('MainPage'), initial: true, path: ''),
                  AutoRoute(
                    page: _page('AuthRequiredPage'),
                    path: 'auth_required_page',
                    guards: [
                      AutoRouteGuard.simple(
                        (resolver, _) => isLoggedIn.value
                            ? resolver.next()
                            : resolver.reject(),
                      ),
                    ],
                  ),
                ],
              ),
              AutoRoute(page: _page('ProfilePage'), path: 'profile'),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router, reevaluationNotifier: isLoggedIn);
      final mainStack = router
          .innerRouterOf<TabsRouter>('HomeRoute')!
          .innerRouterOf<StackRouter>('MainRoute')!;
      unawaited(mainStack.push(const NamedRoute('AuthRequiredPage')));
      await tester.pumpAndSettle();
      expect(find.text('AuthRequiredPage'), findsOneWidget);

      isLoggedIn.value = false;
      await tester.pumpAndSettle();

      expect(find.text('AuthRequiredPage'), findsNothing);
      expect(find.text('MainPage'), findsOneWidget);
      expect(router.urlState.url, '/');
    });
  });
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
