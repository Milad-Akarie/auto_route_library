import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// #1207: on desktop, navigateBack, now named back, flip flopped between two
// pages across nested routers and never reached the first page.
// Steps: Welcome is the initial page at '/welcome'. Dashboard at
// '/dashboard' hosts Home at 'home', its initial child, and Clients at
// 'clients', which hosts ClientsList at '' and ClientsView at ':userId'.
// Navigate to Dashboard, then to Clients, then to ClientsView, and go back
// with the router's back method until it can't go back.
// Should: back walks the history in reverse, ClientsList, Home, Welcome, each
// once, and then can't go back.
void main() {
  RootStackRouter buildRouter() => .build(
    routes: [
      NamedRouteDef(
        name: 'WelcomeRoute',
        path: '/welcome',
        initial: true,
        builder: (_, _) => const Scaffold(body: Text('Welcome')),
      ),
      NamedRouteDef(
        name: 'DashboardRoute',
        path: '/dashboard',
        builder: (_, _) => Scaffold(
          appBar: AppBar(title: const Text('Menu')),
          body: const AutoRouter(),
        ),
        children: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: 'home',
            initial: true,
            builder: (_, _) => const Text('Home'),
          ),
          NamedRouteDef(
            name: 'ClientsRoute',
            path: 'clients',
            builder: (_, _) => const AutoRouter(),
            children: [
              NamedRouteDef(
                name: 'ClientsListRoute',
                path: '',
                builder: (_, _) => const Text('Clients list'),
              ),
              NamedRouteDef(
                name: 'ClientsViewRoute',
                path: ':userId',
                builder: (_, data) =>
                    Text('Client ${data.params.getString('userId')}'),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  testWidgets(
    'back() through nested routers walks the history once each',
    (tester) async {
      final router = buildRouter();
      await pumpRouterApp(tester, router);
      unawaited(router.navigate(const NamedRoute('DashboardRoute')));
      await tester.pumpAndSettle();
      unawaited(router.navigate(const NamedRoute('ClientsRoute')));
      await tester.pumpAndSettle();
      unawaited(
        router.navigate(
          const NamedRoute('ClientsViewRoute', params: {'userId': '7'}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Client 7'), findsOneWidget);
      expect(router.urlState.path, '/dashboard/clients/7');

      final shown = <String>[];
      while (router.canNavigateBack) {
        router.back();
        await tester.pumpAndSettle();
        shown.add(router.urlState.path);
      }

      expect(tester.takeException(), isNull);
      expect(shown, ['/dashboard/clients', '/dashboard/home', '/welcome']);
      expect(find.text('Welcome'), findsOneWidget);
    },
    skip: kIsWeb,
    // back() on web moves the browser's history, which this runner keeps in
    // memory.
  );

  // The comment's case: maybePop on a nested router with no pages of its
  // own goes to the parent router instead of stopping.
  testWidgets('maybePop on an empty nested router pops its host page', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          initial: true,
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        NamedRouteDef(
          name: 'ShellRoute',
          path: '/shell',
          builder: (_, _) => const AutoRouter(),
          children: [
            NamedRouteDef(
              name: 'ChildRoute',
              path: 'child',
              builder: (_, _) => const Text('Child'),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.push(const NamedRoute('ShellRoute')));
    await tester.pumpAndSettle();
    final shell = router.innerRouterOf<StackRouter>('ShellRoute')!;
    expect(shell.stack, isEmpty);

    expect(await shell.maybePop(), isTrue);
    await tester.pumpAndSettle();

    expect(router.stack.map((page) => page.name), ['HomeRoute']);
    expect(find.text('Home'), findsOneWidget);
  });
}
