import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Found while fixing the guard issues, no upstream issue.
// Steps: the router has a reevaluateListenable. The app's first route is
// guarded by AutoRouteGuard.simple with an async callback that waits before it
// calls resolver.next(). Fire the listenable while the callback still waits.
// Was: the re-check called the callback a second time, because the simple
// guard dropped the callback's future, and the second resolver.next() failed
// "Make sure `resolver.next()` is only called once."
// Should: the re-check waits for the running callback, which runs once, and
// the guarded page opens.
void main() {
  testWidgets('a guard re-check waits for an async simple guard still running', (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/profile';
    addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);
    var guardCalls = 0;
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
          guards: [
            AutoRouteGuard.simple((resolver, _) async {
              guardCalls++;
              await Future<void>.delayed(const Duration(milliseconds: 100));
              resolver.next();
            }),
          ],
          builder: (_, __) => const Scaffold(body: Text('ProfileRoute')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config(reevaluateListenable: auth)));
    auth.value++;
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(guardCalls, 1);
    expect(router.topRoute.name, 'ProfileRoute');
    expect(find.text('ProfileRoute'), findsOneWidget);
  });
}
