import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// Going back from the login page a logout redirected to never comes back to it.
// flutter/flutter#135359
// Headless test: auto_route/test/web/redirect_history_web_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: logged in, push Screen3, whose guard redirects to SignInRoute when
  // logged out, with reevaluateListenable set to the login state. Log out,
  // then go back: the browser's back button on web, system back elsewhere.
  // On web, press the browser's back button once more.
  // Should: the first back shows HomeRoute, not SignInRoute again; on web the
  // browser is one entry back, and the next press steps back once more.
  testWidgets(
    'Going back after a logout redirect shows the page before (flutter/flutter#135359)',
    (tester) async {
      final loggedIn = ValueNotifier(true);
      addTearDown(loggedIn.dispose);
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => const TextPage('HomeRoute'),
          ),
          NamedRouteDef(
            name: 'Screen3Route',
            path: '/screen3',
            guards: [
              AutoRouteGuard.simple((resolver, _) {
                if (loggedIn.value) {
                  resolver.next();
                } else {
                  unawaited(
                    resolver.redirectUntil(const NamedRoute('SignInRoute')),
                  );
                }
              }),
            ],
            builder: (_, _) => const TextPage('Screen3Route'),
          ),
          NamedRouteDef(
            name: 'SignInRoute',
            path: '/signin',
            builder: (_, _) => const TextPage('SignInRoute'),
          ),
        ],
      );
      await pumpRouterConfigApp(
        tester,
        router.config(
          reevaluateListenable: loggedIn,
          deepLinkBuilder: (link) => link.initial ? DeepLink.defaultPath : link,
        ),
      );
      final start = browserEntryIndex() ?? 0;
      unawaited(router.push(const NamedRoute('Screen3Route')));
      await pumpUntilFound(tester, find.text('Screen3Route'));

      loggedIn.value = false;
      await pumpUntilFound(tester, find.text('SignInRoute'));
      await expectBrowserUrl('/signin');

      if (kIsWeb) {
        pressBrowserBack();
        await expectBrowserEntry(start + 1);
        await tester.pumpAndSettle();
      } else {
        await systemBack(tester);
      }
      expect(router.stack.map((e) => e.routeData.name), ['HomeRoute']);
      expect(find.text('HomeRoute'), findsOneWidget);
      await expectBrowserUrl('/');

      if (kIsWeb) {
        pressBrowserBack();
        await expectBrowserEntry(start);
        await tester.pumpAndSettle();
        expect(router.stack.map((e) => e.routeData.name), ['HomeRoute']);
      }
      expect(tester.takeException(), isNull);
    },
  );
}
