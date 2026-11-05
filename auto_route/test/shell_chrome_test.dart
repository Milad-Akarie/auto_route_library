import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'named_page.dart';
import 'router_test_utils.dart';

// flutter/flutter#117730, #118645, #119194, #120665, #122271, #125752 and
// #130406: in go_router the shell's chrome (a nav bar) was shown over pages
// that should cover it, hidden for pages inside the shell, or the route data
// of the shell was wrong after push and pop.
// Setup: a shell '/app' with a nav bar and nested pages 'users' > ':id', and
// a sibling page '/settings' outside the shell.
// Steps: push pages in the shell's router, replace one, push from the
// root, pop each, and open the shell from '/settings'.
// Should: pages in the shell's router show the bar, pages pushed on the root
// cover it, a replace in the shell keeps it, and the route data matches the
// visible page every time.
RootStackRouter _router() => .build(
  routes: [
    NamedRouteDef(name: 'HomeRoute', path: '/', builder: (_, _) => const NamedPage('HomeRoute')),
    NamedRouteDef(name: 'SettingsRoute', path: '/settings', builder: (_, _) => const NamedPage('SettingsRoute')),
    NamedRouteDef(
      name: 'AppRoute',
      path: '/app',
      builder: (_, _) => const Column(
        children: [
          Text('NavBar'),
          Expanded(child: AutoRouter()),
        ],
      ),
      children: [
        NamedRouteDef(name: 'FeedRoute', path: '', builder: (_, _) => const NamedPage('FeedRoute')),
        NamedRouteDef(name: 'UsersRoute', path: 'users', builder: (_, _) => const NamedPage('UsersRoute')),
        NamedRouteDef(name: 'UserRoute', path: 'users/:id', builder: (_, _) => const NamedPage('UserRoute')),
        NamedRouteDef(name: 'OtherRoute', path: 'other', builder: (_, _) => const NamedPage('OtherRoute')),
      ],
    ),
  ],
);

void main() {
  testWidgets('Pages pushed in the shell keep its bar, a root push covers it, and pops restore it', (tester) async {
    final router = _router();
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const NamedRoute('AppRoute')));
    await tester.pumpAndSettle();
    final inner = router.innerRouterOf<StackRouter>('AppRoute')!;

    unawaited(inner.push(const NamedRoute('UsersRoute')));
    await tester.pumpAndSettle();
    unawaited(inner.push(const NamedRoute('UserRoute', params: {'id': '3'})));
    await tester.pumpAndSettle();
    expect(find.text('NavBar'), findsOneWidget);
    expect(find.text('UserRoute'), findsOneWidget);
    expect(router.currentUrl, '/app/users/3');
    expect(router.topRoute.name, 'UserRoute');

    // From the grandchild to its parent's url by navigate.
    unawaited(router.navigatePath('/app/users'));
    await tester.pumpAndSettle();
    expect(find.text('UsersRoute'), findsOneWidget);
    expect(router.currentUrl, '/app/users');

    unawaited(inner.replace(const NamedRoute('OtherRoute')));
    await tester.pumpAndSettle();
    expect(find.text('NavBar'), findsOneWidget);
    expect(find.text('OtherRoute'), findsOneWidget);

    unawaited(router.root.push(const NamedRoute('SettingsRoute')));
    await tester.pumpAndSettle();
    expect(find.text('SettingsRoute'), findsOneWidget);
    expect(find.text('NavBar'), findsNothing);
    expect(router.currentUrl, '/settings');

    await router.maybePopTop();
    await tester.pumpAndSettle();
    expect(find.text('NavBar'), findsOneWidget);
    expect(find.text('OtherRoute'), findsOneWidget);
    expect(router.currentUrl, '/app/other');
    expect(router.topRoute.name, 'OtherRoute');
  });

  testWidgets('Opening a shell page from a page outside it shows the shell with its bar', (tester) async {
    final router = _router();
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const NamedRoute('SettingsRoute')));
    await tester.pumpAndSettle();
    expect(find.text('NavBar'), findsNothing);

    unawaited(router.push(const NamedRoute('AppRoute', children: [NamedRoute('UsersRoute')])));
    await tester.pumpAndSettle();
    expect(find.text('NavBar'), findsOneWidget);
    expect(find.text('UsersRoute'), findsOneWidget);
    expect(router.currentUrl, '/app/users');

    unawaited(router.innerRouterOf<StackRouter>('AppRoute')!.replace(const NamedRoute('OtherRoute')));
    await tester.pumpAndSettle();
    expect(find.text('NavBar'), findsOneWidget);
    expect(find.text('OtherRoute'), findsOneWidget);
  });
}
