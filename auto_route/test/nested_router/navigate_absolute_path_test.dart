import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          initial: true,
          page: const EmptyShellRoute('UserShellRoute'),
          children: [
            AutoRoute(path: 'notifications', page: _page('NotificationsRoute')),
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
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/2317
  // '/' holds a shell with 'notifications', an index shell at '' and a '*'
  // not-found route. A button on the home page calls
  // context.router.navigatePath('/notifications'). The notifications page
  // should open, as it does when the app is opened at that url, not the
  // not-found page.
  testWidgets('navigatePath() with an absolute path from a nested page opens its page', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    expect(find.text('HomeRoute'), findsOneWidget);

    await tester.tap(find.text('Open notifications'));
    await tester.pumpAndSettle();
    expect(find.text('NotFoundRoute'), findsNothing);
    expect(find.text('NotificationsRoute'), findsOneWidget);
    expect(router.currentPath, '/notifications');
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/2317
  // The same url opened directly, the way a browser refresh opens it.
  testWidgets('the same url opened directly shows the notifications page', (tester) async {
    await pumpRouterApp(tester, router, initialLink: '/notifications');
    expect(find.text('NotificationsRoute'), findsOneWidget);
    expect(router.currentPath, '/notifications');
  });

  // A path that only the not-found route takes still opens it.
  testWidgets('navigatePath() with an unknown absolute path opens the not-found page', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    router.navigatePath('/unknown/page');
    await tester.pumpAndSettle();
    expect(find.text('NotFoundRoute'), findsOneWidget);
  });
}

PageInfo _page(String name) => .new(name, builder: (_) => Text(name));

final _homePage = PageInfo('HomeRoute', builder: (_) => const _HomePage());

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('HomeRoute'),
        TextButton(
          onPressed: () => context.router.navigatePath('/notifications'),
          child: const Text('Open notifications'),
        ),
      ],
    );
  }
}
