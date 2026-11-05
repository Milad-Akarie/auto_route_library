import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Two RedirectRoutes that send the url to each other report the loop instead
// of overflowing the stack.
// https://github.com/flutter/flutter/issues/104441
// Headless test: auto_route/test/guards/redirect_route_cycle_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: on '/', push '/a', a RedirectRoute to '/b', itself a RedirectRoute
  // to '/a'.
  // Should: the push fails with an error that names both paths, and the app
  // stays on '/'.
  testWidgets('RedirectRoutes pointing at each other report the loop (flutter/flutter#104441)', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
        ),
        RedirectRoute(path: '/a', redirectTo: '/b'),
        RedirectRoute(path: '/b', redirectTo: '/a'),
      ],
    );
    await pumpRouterApp(tester, router);

    expect(
      () => router.pushPath('/a'),
      throwsA(
        isA<FlutterError>().having(
          (e) => e.toString(),
          'message',
          allOf(contains('Redirect loop'), contains('/a'), contains('/b')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('HomeRoute'), findsOneWidget);
  });
}
