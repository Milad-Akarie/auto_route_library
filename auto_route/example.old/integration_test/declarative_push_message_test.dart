import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/declarative_push_router.dart';

// Pushing a route of a router that AutoRouter.declarative builds fails with a
// message naming that router and saying how to change its pages.
// https://github.com/Milad-Akarie/auto_route_library/issues/2127
// Headless test: auto_route/test/nested_router/declarative_push_message_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: HostRoute '/' builds AutoRouter.declarative with ARoute; push
  // BRoute, one of its routes, from the root router.
  // Should: the assert names "the router of HostRoute" and the fix.
  testWidgets(
    'pushing a route of a declarative router names the router and the fix',
    (tester) async {
      final router = buildDeclarativePushRouter();
      await pumpRouterApp(tester, router);
      expect(find.text('A'), findsOneWidget);

      await expectLater(
        router.push(const NamedRoute('BRoute')),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('router of HostRoute'),
              contains('routes callback'),
              contains('AutoRouter()'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsNothing);
    },
  );
}
