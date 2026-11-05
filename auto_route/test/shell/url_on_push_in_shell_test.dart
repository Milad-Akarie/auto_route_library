import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/flutter/flutter/issues/184055
// Setup, as in the report: a shell with tabs around home, reports, sales and
// a sales detail page, all children of the shell.
// Steps: on the sales page, push the detail page by its full path, or by its
// route; then pop it.
// Should: the url Flutter sends the browser changes to the detail page's
// path, so a refresh opens the same page, and back to the sales page's path
// after the pop.
void main() {
  for (final (how, push) in [
    ("pushPath('/reports/sales/detail')", (StackRouter router) => router.pushPath('/reports/sales/detail')),
    ('push(SalesDetailRoute())', (StackRouter router) => router.push(const _Route('SalesDetailRoute'))),
  ]) {
    testWidgets('Pushing in a shell with $how updates the browser url', (tester) async {
      final sentUrls = <String>[];
      final messenger = tester.binding.defaultBinaryMessenger
        ..setMockMethodCallHandler(SystemChannels.navigation, (call) async {
          if (call.method == 'routeInformationUpdated') sentUrls.add((call.arguments as Map)['uri'] as String);
          return null;
        });
      addTearDown(() => messenger.setMockMethodCallHandler(SystemChannels.navigation, null));

      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: const EmptyShellRoute('TabShellRoute'),
            children: [
              AutoRoute(path: '', page: _page('HomeRoute')),
              AutoRoute(path: 'reports', page: _page('ReportsRoute')),
              AutoRoute(path: 'reports/sales', page: _page('SalesRoute')),
              AutoRoute(path: 'reports/sales/detail', page: _page('SalesDetailRoute')),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router, initialLink: '/reports/sales');
      expect(find.text('SalesRoute'), findsOneWidget);
      expect(sentUrls.lastOrNull, '/reports/sales');

      final salesRouter = tester.element(find.text('SalesRoute')).router;
      unawaited(push(salesRouter));
      await tester.pumpAndSettle();
      expect(find.text('SalesDetailRoute'), findsOneWidget);
      expect(router.innerRouterOf<StackRouter>('TabShellRoute')!.topRoute.name, 'SalesDetailRoute');
      expect(sentUrls.lastOrNull, '/reports/sales/detail');

      salesRouter.pop();
      await tester.pumpAndSettle();
      expect(find.text('SalesRoute'), findsOneWidget, reason: 'after salesRouter.pop()');
      expect(sentUrls.lastOrNull, '/reports/sales', reason: 'after salesRouter.pop()');
    });
  }
}

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
