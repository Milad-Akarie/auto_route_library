import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1978
// Setup, as in the report: MaterialApp.router with appRouter.config(), the
// first page right after the splash screen; the reporter has a guard, and
// says it also happens without it. The cause the report points at is the
// placeholder shown while the navigator has no pages.
// Steps: build the app, then pump single frames until the first page shows.
// Reported: a blank screen shows for a moment, for seconds in debug mode.
// Should: the first page is on screen after the first frame that runs the
// router's first route, and no frame before it shows a blank screen
// instead of the placeholder given with config(placeholder:).
void main() {
  RootStackRouter buildRouter({bool guarded = false}) => .build(
    routes: [
      NamedRouteDef(
        name: 'HomeRoute',
        path: '/',
        initial: true,
        guards: [
          if (guarded) AutoRouteGuard.simple((resolver, _) => resolver.next()),
        ],
        builder: (_, _) => const Scaffold(body: Text('Home')),
      ),
    ],
  );

  for (final guarded in [false, true]) {
    final kind = guarded ? 'a synchronous guard' : 'no guard';
    testWidgets('With $kind the first page shows after one more frame, and '
        'no frame is blank', (tester) async {
      final router = buildRouter(guarded: guarded);
      final config = router.config(
        placeholder: (_) => const Text('Placeholder'),
      );
      addTearDown((config.routerDelegate as AutoRouterDelegate).dispose);

      bool isBlank() =>
          find.text('Home').evaluate().isEmpty &&
          find.text('Placeholder').evaluate().isEmpty;

      await tester.pumpWidget(MaterialApp.router(routerConfig: config));
      expect(
        isBlank(),
        isFalse,
        reason: 'after the first frame of MaterialApp.router',
      );

      await tester.pump();
      expect(
        find.text('Home'),
        findsOneWidget,
        reason: 'after one more tester.pump()',
      );
    });
  }
}
