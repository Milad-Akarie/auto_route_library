import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'auth_state.dart';

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

// Reproduction for https://github.com/Milad-Akarie/auto_route_library/issues/1740
// (with the second report in its comments, a guard that redirects on a child
// of a guarded parent).
// Setup, as reported: a home page with an AutoTabsRouter whose first tab,
// MainRoute, has the children MainPage and AuthRequiredPage; AuthRequiredPage
// has a guard that lets in only a logged-in user; the second tab is Profile.
// The router gets reevaluateListenable: the auth state. Also run with an
// AutoRouter in place of the AutoTabsRouter, which the reports never tried.
// Steps: log in, open AuthRequiredPage inside the first tab, log out.
// Reported: the guard was not asked again and AuthRequiredPage stayed.
// Before this fix: the guard is asked, but a child that is the only page of
// its stack stayed on screen, and with a page below it the url stayed the
// closed page's.
// Should: the guard is asked again, rejects, and AuthRequiredPage closes; the
// tab shows MainPage, also when the child was alone in its stack, and the url
// is that of MainPage, in place of the closed page's entry.
void main() {
  final hosts = <String, Widget Function()>{
    'tabs': () => const AutoTabsRouter(),
    'a nested stack': () => const AutoRouter(),
  };

  RootStackRouter buildRouter(
    Widget Function() host,
    AutoRouteGuard guard, {
    List<AutoRoute> extraRoutes = const [],
  }) => .build(
    routes: [
      AutoRoute(
        page: PageInfo('HomeRoute', builder: (_) => host()),
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
                guards: [guard],
              ),
            ],
          ),
          AutoRoute(page: _page('ProfilePage'), path: 'profile'),
        ],
      ),
      ...extraRoutes,
    ],
  );

  // Opens the guarded child inside MainRoute's own stack, as the reports do.
  Future<void> openGuardedChild(
    WidgetTester tester,
    RootStackRouter router,
  ) async {
    final mainStack = router
        .innerRouterOf<RoutingController>('HomeRoute')!
        .innerRouterOf<StackRouter>('MainRoute')!;
    unawaited(mainStack.push(const NamedRoute('AuthRequiredPage')));
    await tester.pumpAndSettle();
    expect(find.text('AuthRequiredPage'), findsOneWidget);
    expect(router.urlState.url, '/auth_required_page');
  }

  void expectBackOnMainPage(RootStackRouter router) {
    expect(find.text('AuthRequiredPage'), findsNothing);
    expect(find.text('MainPage'), findsOneWidget);
    expect(router.urlState.url, '/');
    expect(router.urlState.shouldReplace, isTrue);
  }

  for (final MapEntry(key: name, value: host) in hosts.entries) {
    testWidgets('Logging out closes a guarded child in $name (#1740)', (
      tester,
    ) async {
      final auth = AuthState()..isLoggedIn = true;
      addTearDown(auth.dispose);
      var asked = 0;
      final router = buildRouter(
        host,
        AutoRouteGuard.simple((resolver, _) {
          asked++;
          auth.isLoggedIn ? resolver.next() : resolver.reject();
        }),
      );
      await pumpRouterApp(tester, router, reevaluationNotifier: auth);
      await openGuardedChild(tester, router);
      final askedBeforeLogout = asked;

      auth.isLoggedIn = false;
      await tester.pumpAndSettle();

      expect(asked, greaterThan(askedBeforeLogout));
      expectBackOnMainPage(router);
    });

    testWidgets('Logging out shows MainPage when the guarded child is the only '
        'page of its stack in $name (#1740)', (tester) async {
      final auth = AuthState()..isLoggedIn = true;
      addTearDown(auth.dispose);
      final router = buildRouter(
        host,
        AutoRouteGuard.simple(
          (resolver, _) =>
              auth.isLoggedIn ? resolver.next() : resolver.reject(),
        ),
      );
      await pumpRouterApp(tester, router, reevaluationNotifier: auth);
      // From the root router, around the tabs: a new HomeRoute whose MainRoute
      // holds the guarded child alone.
      unawaited(router.pushPath('/auth_required_page'));
      await tester.pumpAndSettle();
      expect(find.text('AuthRequiredPage'), findsOneWidget);

      auth.isLoggedIn = false;
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expectBackOnMainPage(router);
    });

    testWidgets('Logging out sends a guarded child in $name to the redirect '
        '(#1740)', (tester) async {
      final auth = AuthState()..isLoggedIn = true;
      addTearDown(auth.dispose);
      final router = buildRouter(
        host,
        AutoRouteGuard.redirect(
          (_) => auth.isLoggedIn ? null : const NamedRoute('LoginRoute'),
        ),
        extraRoutes: [AutoRoute(page: _page('LoginRoute'), path: '/login')],
      );
      await pumpRouterApp(tester, router, reevaluationNotifier: auth);
      await openGuardedChild(tester, router);

      auth.isLoggedIn = false;
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('LoginRoute'), findsOneWidget);
      expect(router.urlState.url, '/login');
    });
  }
}
