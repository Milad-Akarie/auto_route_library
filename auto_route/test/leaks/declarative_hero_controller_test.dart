import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'disposal_tracker.dart';

void main() {
  // Steps: push HostRoute, whose page holds an AutoRouter.declarative given
  // a heroControllerBuilder, then pop it.
  // Happened: the HeroController the declarative router creates stayed
  // undisposed, one more on each visit.
  // Should: popping the host disposes it.
  testWidgets('Popping a declarative router disposes its HeroController', (
    tester,
  ) async {
    final heroControllers = await _visitHost(
      tester,
      heroControllerBuilder: HeroController.new,
    );
    expect((heroControllers.created, heroControllers.undisposed), (1, 0));
  });

  // Steps: the same, without a heroControllerBuilder.
  // Should: the declarative router creates no HeroController of its own.
  testWidgets('A declarative router without the builder creates none', (
    tester,
  ) async {
    final heroControllers = await _visitHost(tester);
    expect(heroControllers.created, 0);
  });
}

/// Pushes a host page holding an [AutoRouter.declarative] built with
/// [heroControllerBuilder], pops it, and returns the tracker of the
/// [HeroController]s created on the way.
Future<DisposalTracker<HeroController>> _visitHost(
  WidgetTester tester, {
  HeroController Function()? heroControllerBuilder,
}) async {
  final router = RootStackRouter.build(
    routes: [
      AutoRoute(
        path: '/',
        page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
      ),
      AutoRoute(
        path: '/host',
        page: PageInfo(
          'HostRoute',
          builder: (_) => AutoRouter.declarative(
            routes: (_) => [const NamedRoute('ChildRoute')],
            heroControllerBuilder: heroControllerBuilder,
          ),
        ),
        children: [
          AutoRoute(
            path: '',
            page: PageInfo(
              'ChildRoute',
              builder: (_) => const Text('ChildRoute'),
            ),
          ),
        ],
      ),
    ],
  );
  await pumpRouterApp(tester, router);
  // Started after the app, whose own HeroController lives until it closes.
  final heroControllers = DisposalTracker<HeroController>();
  unawaited(router.pushPath('/host'));
  await tester.pumpAndSettle();
  expect(find.text('ChildRoute'), findsOneWidget);

  router.pop();
  await tester.pumpAndSettle();
  expect(find.text('HomeRoute'), findsOneWidget);
  return heroControllers;
}
