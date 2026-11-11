import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';
import 'universal_link_test.dart' show didSendPlatformLink;

// https://github.com/Milad-Akarie/auto_route_library/issues/2260
// Setup: a splash route that is initial, an auth route and a recover route.
// The recover page holds a nested router with a redirect from its empty path
// to the email page, an email page and a change page. The deep link builder
// answers every link with the auth page, then the recover page holding the
// change page.
// Steps: open the app with that link, then send the same link again, the
// way iOS does when it delivers a link twice.
// Reported: the stack ended with the recover page and an empty nested router.
// Should: the change page stays shown, once, with the auth and recover pages
// in the stack.
void main() {
  late int builderCalls;

  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(page: _page('SplashRoute'), path: '/splash', initial: true),
      AutoRoute(page: _page('AuthRoute'), path: '/auth'),
      AutoRoute(
        page: _page('RecoverRoute', child: const AutoRouter()),
        path: '/auth/recover',
        children: [
          RedirectRoute(path: '', redirectTo: 'email'),
          AutoRoute(page: _page('EmailRoute'), path: 'email'),
          AutoRoute(page: _page('ChangeRoute'), path: 'change'),
        ],
      ),
    ],
  );

  Future<RootStackRouter> pumpWithLink(WidgetTester tester) async {
    final router = buildRouter();
    builderCalls = 0;
    await pumpRouterConfigApp(
      tester,
      router.config(
        deepLinkBuilder: (link) {
          builderCalls++;
          return const DeepLink([
            PageRouteInfo('AuthRoute'),
            PageRouteInfo(
              'RecoverRoute',
              initialChildren: [PageRouteInfo('ChangeRoute')],
            ),
          ]);
        },
      ),
    );
    return router;
  }

  testWidgets('A link with a nested child opens the child', (tester) async {
    final router = await pumpWithLink(tester);
    expect(router.stack.map((page) => page.name), [
      'AuthRoute',
      'RecoverRoute',
    ]);
    expect(find.text('ChangeRoute'), findsOneWidget);
  });

  testWidgets('The same link sent a second time keeps the child shown', (
    tester,
  ) async {
    final router = await pumpWithLink(tester);

    await didSendPlatformLink(tester, '/auth/recover/change');
    expect(builderCalls, greaterThan(0));
    expect(router.stack.map((page) => page.name), [
      'AuthRoute',
      'RecoverRoute',
    ]);
    expect(find.text('ChangeRoute'), findsOneWidget);
    expect(
      router.innerRouterOf<StackRouter>('RecoverRoute')?.stack,
      isNotEmpty,
    );
  });
}

PageInfo _page(String name, {Widget? child}) =>
    .new(name, builder: (_) => Scaffold(body: child ?? Text(name)));
