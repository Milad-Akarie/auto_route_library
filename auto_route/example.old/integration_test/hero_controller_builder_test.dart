import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A nested router given heroControllerBuilder flies Heroes between its pages.
// https://github.com/Milad-Akarie/auto_route_library/issues/372
// https://github.com/flutter/flutter/issues/90103
// Headless tests: auto_route/test/transitions/hero_controller_builder_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('hero controller builder', () {
    // Steps: a nested router's first page has a Hero at its bottom left; tap
    // its button to push a second page with the same Hero at its top right,
    // inside the same router.
    // Should: with heroControllerBuilder the Hero flies; its child leaves the
    // first page. Without it the Hero stays on its page.
    testWidgets('A Hero flies between two pages of a nested router', (
      tester,
    ) async {
      await pumpRouterAppWithConfig(
        tester,
        _router(MaterialApp.createMaterialHeroController),
      );
      await _openSecondPage(tester);
      expect(
        (
          find.text('from').evaluate().length,
          find.text('to').evaluate().length,
        ),
        (0, 1),
        reason: 'the source Hero should have left its page',
      );
      await tester.pumpAndSettle();
      expect(find.text('to'), findsOneWidget);
    });

    testWidgets('A Hero stays put in a nested router without the builder', (
      tester,
    ) async {
      await pumpRouterAppWithConfig(tester, _router(null));
      await _openSecondPage(tester);
      expect(
        find.text('from'),
        findsOneWidget,
        reason: 'without a HeroController the Hero stays on its page',
      );
      await tester.pumpAndSettle();
      expect(find.text('to'), findsOneWidget);
    });
  });
}

/// A router whose first page holds a nested [AutoRouter] built with
/// [heroControllerBuilder], over the two Hero pages.
RootStackRouter _router(HeroController Function()? heroControllerBuilder) =>
    .build(
      routes: [
        NamedRouteDef(
          name: 'HostRoute',
          path: '/',
          builder: (_, _) =>
              AutoRouter(heroControllerBuilder: heroControllerBuilder),
          children: [
            NamedRouteDef(
              name: 'FromRoute',
              path: '',
              builder: (_, _) => const _HeroPage('from', .bottomLeft),
            ),
            NamedRouteDef(
              name: 'ToRoute',
              path: 'to',
              builder: (_, _) => const _HeroPage('to', .topRight),
            ),
          ],
        ),
      ],
    );

/// Taps the first page's button and pumps into the transition. The runner's
/// clock is real, so the checks leave out where the Hero is.
Future<void> _openSecondPage(WidgetTester tester) async {
  expect(find.text('from'), findsOneWidget);
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

/// A page with a Hero box showing [name], placed at [alignment], and a button
/// that pushes the second page into the same router.
class _HeroPage extends StatelessWidget {
  const new(this.name, this.alignment);

  final String name;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: alignment,
              child: Hero(
                tag: 'box',
                child: SizedBox(width: 50, height: 50, child: Text(name)),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () =>
                    unawaited(context.router.push(const NamedRoute('ToRoute'))),
                child: const Text('open'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
