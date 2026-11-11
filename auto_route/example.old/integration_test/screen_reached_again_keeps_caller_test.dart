import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';
import 'support/picker_router.dart';

// A navigation that reaches a screen already shown keeps the wait of the code
// that opened the screen.
// Headless test:
// auto_route/test/simple_router/screen_reached_again_keeps_caller_test.dart
// Flutter's Navigator keeps a route, with its pending future, for a page of
// the same type and key, and Android's Navigation keeps the back stack entry
// of a screen a single-top navigation reaches again.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('screen reached again keeps caller', () {
    // Steps: start an app whose home page has a guard that shows WelcomeRoute
    // with redirectUntil and never lets the home page in, then navigate to
    // /welcome by its path, as a link inside the app or an address bar does.
    // Happened: since 12.6.0, the screen went blank: the redirect's wait ended
    // as if WelcomeRoute had closed, so the guard rejected the home page, and
    // removing the redirect took the link's page off.
    // Should: WelcomeRoute stays on screen at /welcome.
    testWidgets('A link to the redirect a guard shows keeps it on screen', (
      tester,
    ) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            guards: [
              AutoRouteGuard.simple((resolver, _) {
                unawaited(
                  resolver.redirectUntil(const NamedRoute('WelcomeRoute')),
                );
              }),
            ],
            builder: (_, _) => const TextPage('Home'),
          ),
          NamedRouteDef(
            name: 'WelcomeRoute',
            path: '/welcome',
            builder: (_, _) => const TextPage('Welcome'),
          ),
        ],
      );
      await pumpRouterAppWithConfig(tester, router);
      expect(router.topRoute.name, 'WelcomeRoute');

      unawaited(router.navigatePath('/welcome'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome'), findsOneWidget);
      expect(router.stack.map((page) => page.name), ['WelcomeRoute']);
      await expectBrowserUrl('/welcome');
    });

    // Steps: push PickerRoute<int> with push<int>, navigate to PickerRoute
    // with other items and title, as the app does for a link to it, then tap
    // an item.
    // Happened: since 12.6.0, the push answered null at the navigation, while
    // the picker stayed on screen, and the item tapped went to no one.
    // Should: the push waits while the picker shows, and gets the item.
    testWidgets('The caller of a picker reached again gets the item tapped', (
      tester,
    ) async {
      final router = PickerRouter();
      await pumpRouterAppWithConfig(tester, router);
      var result = 'waiting';
      unawaited(
        router
            .push<int>(PickerRoute<int>(items: const [1, 2, 3]))
            .then((value) => result = 'got ${value ?? 'null'}'),
      );
      await tester.pumpAndSettle();

      unawaited(
        router.navigate(PickerRoute<int>(items: const [4, 5], title: 'Again')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Again from 2'), findsOneWidget);
      await expectBrowserUrl('/picker?title=Again');
      expect(result, 'waiting');

      await tester.tap(find.text('Item 5'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(result, 'got 5');
    });
  });
}
