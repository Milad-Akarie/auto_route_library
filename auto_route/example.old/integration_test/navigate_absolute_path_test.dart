import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// navigatePath() with an absolute path from a nested page opens its page.
// https://github.com/Milad-Akarie/auto_route_library/issues/2317
// Headless test: auto_route/test/nested_router/navigate_absolute_path_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: '/' holds a shell with 'notifications', an index shell at '' and
  // a '*' not-found route. Tap the button on the home page that calls
  // context.router.navigatePath('/notifications').
  // Should: the notifications page opens at '/notifications', not the
  // not-found page.
  testWidgets(
    'navigatePath() with an absolute path from a nested page opens its page',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            initial: true,
            page: const EmptyShellRoute('UserShellRoute'),
            children: [
              AutoRoute(
                path: 'notifications',
                page: _page('NotificationsRoute'),
              ),
              AutoRoute(
                path: '',
                initial: true,
                page: const EmptyShellRoute('IndexRoute'),
                children: [
                  AutoRoute(path: '', initial: true, page: _homePage),
                  AutoRoute(path: ':id', page: _page('DynamicRoute')),
                ],
              ),
              AutoRoute(path: '*', page: _page('NotFoundRoute')),
            ],
          ),
        ],
      );
      await pumpRouterAppWithConfig(tester, router);
      expect(find.text('HomeRoute'), findsOneWidget);

      await tester.tap(find.text('Open notifications'));
      await tester.pumpAndSettle();
      expect(find.text('NotFoundRoute'), findsNothing);
      expect(find.text('NotificationsRoute'), findsOneWidget);
      expect(router.currentPath, '/notifications');
      await expectBrowserUrl('/notifications');
    },
  );
}

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(body: Center(child: Text(name))),
);

final _homePage = PageInfo('HomeRoute', builder: (_) => const _HomePage());

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('HomeRoute'),
          TextButton(
            onPressed: () => context.router.navigatePath('/notifications'),
            child: const Text('Open notifications'),
          ),
        ],
      ),
    );
  }
}
