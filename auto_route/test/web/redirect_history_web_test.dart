@TestOn('browser')
library;

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();

  setUp(rewindBrowserHistory);

  // https://github.com/Milad-Akarie/auto_route_library/issues/2331
  // The app opens on HomeRoute, whose guard calls
  // redirectUntil(LoginRoute(next: resolver.next)), and LoginRoute calls next()
  // after its first frame.
  // The back button must not reopen LoginRoute with a resolver that was already
  // used. The phone history kept LoginRoute's entry; the browser history never
  // goes back past the app's first entry, so on web this only guards that.
  testWidgets('The browser back button after a resolved redirect on web stays on the guarded page (#2331)', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          guards: [
            AutoRouteGuard.simple((resolver, _) {
              resolver.redirectUntil(NamedRoute('LoginRoute', args: resolver.next));
            }),
          ],
          builder: (_, __) => const Scaffold(body: Text('HomeRoute')),
        ),
        NamedRouteDef(
          name: 'LoginRoute',
          path: '/login',
          builder: (_, data) {
            final next = data.args as VoidCallback;
            WidgetsBinding.instance.addPostFrameCallback((_) => next());
            return const Scaffold(body: Text('LoginRoute'));
          },
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    expect(router.stack.map((e) => e.routeData.name), ['HomeRoute']);
    expect(browserPath, '/');
    final entry = browserSerialCount;

    await pressBrowserBack(tester);
    expect(browserSerialCount, entry);
    expect(browserPath, '/');
    expect(router.stack.map((e) => e.routeData.name), ['HomeRoute']);
  });
}
