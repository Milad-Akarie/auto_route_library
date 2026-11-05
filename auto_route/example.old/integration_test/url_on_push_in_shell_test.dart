import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// The browser url follows a page pushed inside a shell.
// https://github.com/flutter/flutter/issues/184055
// Headless test: auto_route/test/shell/url_on_push_in_shell_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('url on push in shell', () {
    // Steps: a shell around home, reports, sales and a sales detail page, all
    // its children. Open the sales page, push the detail page by its full
    // path, or by its route, then pop it.
    // Should: the url is the detail page's path, in the browser's address bar
    // too on web, then the sales page's path again after the pop.
    for (final (how, push) in [
      (
        "pushPath('/reports/sales/detail')",
        (StackRouter router) => router.pushPath('/reports/sales/detail'),
      ),
      (
        'push(SalesDetailRoute())',
        (StackRouter router) => router.push(const _Route('SalesDetailRoute')),
      ),
    ]) {
      testWidgets('Pushing in a shell with $how updates the browser url', (
        tester,
      ) async {
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(
              path: '/',
              page: const EmptyShellRoute('TabShellRoute'),
              children: [
                AutoRoute(path: '', page: _page('HomeRoute')),
                AutoRoute(path: 'reports', page: _page('ReportsRoute')),
                AutoRoute(path: 'reports/sales', page: _page('SalesRoute')),
                AutoRoute(
                  path: 'reports/sales/detail',
                  page: _page('SalesDetailRoute'),
                ),
              ],
            ),
          ],
        );
        await pumpRouterApp(tester, router, initialLink: '/reports/sales');
        expect(find.text('SalesRoute'), findsOneWidget);
        await expectBrowserUrl('/reports/sales');

        final salesRouter = tester.element(find.text('SalesRoute')).router;
        unawaited(push(salesRouter));
        await tester.pumpAndSettle();
        expect(find.text('SalesDetailRoute'), findsOneWidget);
        expect(router.urlState.url, '/reports/sales/detail');
        await expectBrowserUrl('/reports/sales/detail');

        salesRouter.pop();
        await tester.pumpAndSettle();
        expect(find.text('SalesRoute'), findsOneWidget);
        expect(router.urlState.url, '/reports/sales');
        await expectBrowserUrl('/reports/sales');
      });
    }
  });
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
