import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/disposal_tracker.dart';

// Leaving a declarative router disposes the HeroController it creates.
// Headless test: auto_route/test/leaks/declarative_hero_controller_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: push HostRoute, whose page holds an AutoRouter.declarative, then
  // go back, three times.
  // Should: each visit's HeroController is disposed when the host leaves.
  testWidgets('leaving a declarative router disposes its HeroController', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HomeRoute',
            builder: (_) => const _TextPage('HomeRoute'),
          ),
        ),
        AutoRoute(
          path: '/host',
          page: PageInfo(
            'HostRoute',
            builder: (_) => AutoRouter.declarative(
              routes: (_) => [const NamedRoute('ChildRoute')],
            ),
          ),
          children: [
            AutoRoute(
              path: '',
              page: PageInfo(
                'ChildRoute',
                builder: (_) => const _TextPage('ChildRoute'),
              ),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    // Started after the app, whose own HeroController lives until it closes.
    final heroControllers = DisposalTracker<HeroController>();

    for (var visit = 0; visit < 3; visit++) {
      unawaited(router.pushPath('/host'));
      await pumpUntilFound(tester, find.text('ChildRoute'));
      expect(find.text('ChildRoute'), findsOneWidget);

      await systemBack(tester);
      expect(find.text('HomeRoute'), findsOneWidget);
    }
    expect(heroControllers.created, 3);
    expect(heroControllers.undisposed, 0);
  });
}

/// Shows [text] on a plain page.
class _TextPage extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: SafeArea(child: Text(text)));
}
