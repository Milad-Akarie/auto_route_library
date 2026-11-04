@TestOn('browser')
library;

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' show window;

import 'browser_history.dart';

void main() {
  useRealBrowserHistory();

  setUp(rewindBrowserHistory);

  // https://github.com/Milad-Akarie/auto_route_library/issues/2173
  // Reported for 10.0.0 and later on web: with reevaluateListenable set, a url
  // typed in the browser's address bar always opened '/', while without it the
  // app followed the url. The app follows the typed url either way, also when
  // the listenable fires afterwards and when the route is guarded.
  for (final withListenable in [false, true]) {
    testWidgets('A url typed in the address bar opens its page, reevaluateListenable: $withListenable (#2173)', (
      tester,
    ) async {
      final auth = ValueNotifier(0);
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('HomeRoute')),
          ),
          NamedRouteDef(
            name: 'ProfileRoute',
            path: '/profile',
            guards: [AutoRouteGuard.simple((resolver, _) => resolver.next())],
            builder: (_, __) => const Scaffold(body: Text('ProfileRoute')),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router.config(
            reevaluateListenable: withListenable ? auth : null,
            deepLinkBuilder: (link) => link.initial ? const DeepLink.path('/') : link,
          ),
        ),
      );
      await settleBrowser(tester);
      expect(browserPath, '/');

      // Typing a url changes the part after '#' without reloading the page.
      await browserMove(tester, () => window.location.hash = '#/profile');
      expect(router.topRoute.name, 'ProfileRoute');
      expect(browserPath, '/profile');

      auth.value++;
      await settleBrowser(tester);
      expect(router.topRoute.name, 'ProfileRoute');
      expect(find.text('ProfileRoute'), findsOneWidget);
      expect(browserPath, '/profile');
    });
  }
}
