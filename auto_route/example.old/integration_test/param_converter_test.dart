import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/user_router.dart';

// A path or query param of the app's own type is read and written by the
// ParamConverter on its annotation.
// https://github.com/Milad-Akarie/auto_route_library/issues/1794
// Headless tests: auto_route/test/param_converter/param_converter_test.dart
// The router and its page are in support/user_router.dart, with the router
// generated next to it.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('param converter', () {
    // Steps: open the app at the deep link /user/u-7?by=u-3.
    // Should: the profile page shows the ids 7 and 3, read by the converter.
    testWidgets(
      'A deep link reads path and query params through their converter',
      (tester) async {
        final router = UserRouter();
        await pumpRouterApp(tester, router, initialLink: '/user/u-7?by=u-3');
        expect(tester.takeException(), isNull);
        expect(router.current.name, UserProfileRoute.name);
        expect(find.text('User 7 by 3'), findsOneWidget);
      },
    );

    // Steps: push the profile route with the ids 8 and 2.
    // Should: the url carries u-8 and by=u-2, the form the deep link uses.
    testWidgets('Pushing the route writes each param with its converter', (
      tester,
    ) async {
      final router = UserRouter();
      await pumpRouterApp(tester, router);
      unawaited(
        router.push(
          UserProfileRoute(id: const UserId('8'), by: const UserId('2')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('User 8 by 2'), findsOneWidget);
      expect(router.urlState.url, '/user/u-8?by=u-2');
      await expectBrowserUrl('/user/u-8?by=u-2');
    });
  });
}
