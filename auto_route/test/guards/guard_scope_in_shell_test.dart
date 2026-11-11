import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

// Reproduction for https://github.com/Milad-Akarie/auto_route_library/issues/2131
// Setup, as reported: a shell page at '/' with the children RedirectRoute ''
// to 'protected', 'protected' (with a guard) and 'unprotected' (no guard).
// Steps: open the app at '/', which redirects to 'protected' and asks its
// guard (which lets it in); then navigate to 'unprotected'. Then, in a second
// app, a guard that rejects and a link straight to '/unprotected'.
// Should: the guard of 'protected' is never asked for 'unprotected', and
// 'unprotected' shows.
void main() {
  RootStackRouter buildRouter(AutoRouteGuard guard) => .build(
    routes: [
      AutoRoute(
        page: PageInfo('SectionShellRoute', builder: (_) => const AutoRouter()),
        path: '/',
        children: [
          RedirectRoute(path: '', redirectTo: 'protected'),
          AutoRoute(
            page: _page('ProtectedRoute'),
            path: 'protected',
            guards: [guard],
          ),
          AutoRoute(page: _page('UnprotectedRoute'), path: 'unprotected'),
        ],
      ),
    ],
  );

  testWidgets('Navigating to an unguarded sibling does not ask the initial '
      "child's guard (#2131)", (tester) async {
    var asked = 0;
    final router = buildRouter(
      AutoRouteGuard.simple((resolver, _) {
        asked++;
        resolver.next();
      }),
    );
    await pumpRouterApp(tester, router);
    expect(find.text('ProtectedRoute'), findsOneWidget);
    expect(asked, 1);
    final askedAtStart = asked;

    unawaited(router.navigatePath('/unprotected'));
    await tester.pumpAndSettle();

    expect(asked, askedAtStart);
    expect(find.text('UnprotectedRoute'), findsOneWidget);
  });

  testWidgets('A link to an unguarded sibling shows it though the initial '
      "child's guard rejects (#2131)", (tester) async {
    var asked = 0;
    final router = buildRouter(
      AutoRouteGuard.simple((resolver, _) {
        asked++;
        resolver.reject();
      }),
    );
    await pumpRouterApp(tester, router, initialLink: '/unprotected');

    expect(asked, 0);
    expect(find.text('UnprotectedRoute'), findsOneWidget);
  });
}
