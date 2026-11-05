import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A reload on a page whose guard awaits, then calls next(true), shows that
// page.
// https://github.com/Milad-Akarie/auto_route_library/issues/1755
// Headless test: auto_route/test/web/reload_guard_web_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: open the app on '/dashboard', as a reload does on web; its guard
  // waits for a stored user, then calls resolver.next(true).
  // Should: the dashboard shows and the url stays '/dashboard'.
  testWidgets(
    'Opening a page whose guard awaits, then calls next(true), shows that page',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(page: _page('HomeRoute'), path: '/', initial: true),
          AutoRoute(
            page: _page('DashboardRoute'),
            path: '/dashboard',
            guards: [
              AutoRouteGuard.simple((resolver, _) async {
                await Future<void>.delayed(const Duration(milliseconds: 100));
                resolver.next();
              }),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(
        tester,
        router.config(
          deepLinkBuilder: (link) =>
              link.initial ? const DeepLink.path('/dashboard') : link,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expectTopPage(router, 'DashboardRoute');
      await expectBrowserUrl('/dashboard');
    },
  );
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
