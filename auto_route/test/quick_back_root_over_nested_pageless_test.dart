import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// #1977 (auto_route 8.1.3, fixed upstream in a 2024-06 release): "Bad state:
// Future already completed" when a root page was pushed over a nested page
// and Android back was pressed before its animation ended.
// Setup: root 'HomeRoute' shell with 'DashboardRoute' (initial) and the
// shell 'SettingsRouterRoute' holding 'SettingsRoute' (initial). The root also
// has 'CreateActionRoute', a CupertinoRoute with fullscreenDialog. The
// settings page pushed a pageless route (Navigator.of(context).push) in the
// nested navigator.
// Steps: open the settings tab, push the pageless route, push
// CreateActionRoute on the root, press Android back 100 ms into the
// animation.
// Should: no exception; CreateActionRoute is gone and the pageless route is
// shown again.
void main() {
  testWidgets('Quick back on a root page over a nested pageless route', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          initial: true,
          page: PageInfo('HomeRoute', builder: (_) => const AutoRouter()),
          children: [
            AutoRoute(
              path: 'dashboard',
              initial: true,
              page: _page('DashboardRoute'),
            ),
            AutoRoute(
              path: 'settings',
              page: PageInfo(
                'SettingsRouterRoute',
                builder: (_) => const AutoRouter(),
              ),
              children: [
                AutoRoute(
                  path: '',
                  initial: true,
                  page: PageInfo(
                    'SettingsRoute',
                    builder: (_) => Builder(
                      builder: (context) => TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const Text('Pageless'),
                          ),
                        ),
                        child: const Text('Open pageless'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        CupertinoRoute(
          path: '/create-action',
          fullscreenDialog: true,
          page: _page('CreateActionRoute'),
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.navigatePath('/settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open pageless'));
    await tester.pumpAndSettle();
    expect(find.text('Pageless'), findsOneWidget);

    unawaited(router.push(const NamedRoute('CreateActionRoute')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('CreateActionRoute'), findsNothing);
    expect(find.text('Pageless'), findsOneWidget);
    expect(router.stack.map((page) => page.name), ['HomeRoute']);
  }, variant: TargetPlatformVariant.only(.android));
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
