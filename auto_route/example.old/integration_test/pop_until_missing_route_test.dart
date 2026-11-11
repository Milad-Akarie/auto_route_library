import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// popUntilRouteWithName for a page that isn't in the stack keeps the first
// page instead of leaving a blank screen.
// https://github.com/Milad-Akarie/auto_route_library/issues/1502
// Headless test:
// auto_route/test/simple_router/pop_until_missing_route_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('pop until missing route', () {
    // Steps: stack [Page1Route, Page2Route], then
    // popUntilRouteWithName('Page3Route').
    // Should: Page1Route stays on screen.
    testWidgets(
      'popUntilRouteWithName for a missing page keeps the first page',
      (tester) async {
        final router = RootStackRouter.build(
          routes: [
            NamedRouteDef(
              name: 'Page1Route',
              path: '/',
              builder: (_, _) => const TextPage('Page 1'),
            ),
            NamedRouteDef(
              name: 'Page2Route',
              path: '/page2',
              builder: (_, _) => const TextPage('Page 2'),
            ),
          ],
        );
        await pumpRouterApp(tester, router);
        unawaited(router.push(const NamedRoute('Page2Route')));
        await tester.pumpAndSettle();

        router.popUntilRouteWithName('Page3Route');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(router.stack.map((p) => p.name), ['Page1Route']);
        expect(find.text('Page 1'), findsOneWidget);
        await expectBrowserUrl('/');
      },
    );
  });
}
