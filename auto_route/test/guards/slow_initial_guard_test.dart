import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // https://github.com/flutter/flutter/issues/133746
  // In go_router, an async redirect on the first route showed a black screen
  // while it waited.
  // Steps: open the app on HomeRoute, whose guard waits 6 seconds before
  // calling next(); look at the screen after 1 second, then after the wait.
  // Should: during the wait, a placeholder in the theme's scaffold background
  // color fills the screen, with no error; then HomeRoute shows.
  testWidgets('While the first route waits for its guard, a placeholder in the scaffold color shows '
      '(flutter/flutter#133746)', (tester) async {
    const background = Color(0xFFFAFAF0);
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          guards: [
            AutoRouteGuard.simple((resolver, _) async {
              await Future<void>.delayed(const Duration(seconds: 6));
              resolver.next();
            }),
          ],
          builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: ThemeData(scaffoldBackgroundColor: background),
        routerConfig: router.config(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('HomeRoute'), findsNothing);
    final placeholder = tester.widget<Container>(find.byType(Container).first);
    expect(placeholder.color, background);
    expect(tester.getSize(find.byType(Container).first), tester.view.physicalSize / tester.view.devicePixelRatio);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('HomeRoute'), findsOneWidget);
  });
}
