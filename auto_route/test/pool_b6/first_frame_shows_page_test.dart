import 'dart:async';

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
// The reporter's guard is a real one that decides late, such as one that
// reads the stored login first. The last test has the guard wait on a
// completer. Until it answers, the placeholder shows, never a blank
// screen, and the first page shows two frames after it answers, with the placeholder
// still on screen in the first of them.
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

  testWidgets('With a guard that answers late the placeholder shows until '
      'it does, then the first page', (tester) async {
    final answer = Completer<void>();
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          initial: true,
          guards: [
            AutoRouteGuard.simple((resolver, _) {
              unawaited(answer.future.then((_) => resolver.next()));
            }),
          ],
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    final config = router.config(placeholder: (_) => const Text('Placeholder'));
    addTearDown((config.routerDelegate as AutoRouterDelegate).dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: config));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Placeholder'), findsOneWidget);
    expect(find.text('Home'), findsNothing);

    answer.complete();
    await tester.pump();
    expect(
      find.text('Placeholder'),
      findsOneWidget,
      reason: 'the frame right after the answer, before the page is built',
    );
    await tester.pump();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Placeholder'), findsNothing);
  });
}
