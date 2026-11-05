import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// A push made in the same callback that fires reevaluateListenable is no
// longer dropped.
// https://github.com/Milad-Akarie/auto_route_library/issues/2327
// Headless test:
// auto_route/test/reevaluatable_router/reevaluation_listener_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ValueNotifier<bool> reevaluationNotifier;
  setUp(() => reevaluationNotifier = ValueNotifier(false));

  // Steps: with no guards at all, tap a button that calls push(SecondRoute)
  // and then fires reevaluateListenable in the same callback.
  // Should: SecondRoute is pushed and shown above FirstRoute.
  testWidgets(
    'Push followed by reevaluation in the same callback should still push '
    '(#2327)',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            initial: true,
            page: PageInfo(
              FirstRoute.name,
              builder: (_) => Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        unawaited(context.router.push(const SecondRoute()));
                        reevaluationNotifier.value =
                            !reevaluationNotifier.value;
                      },
                      child: const Text('Push and reevaluate'),
                    ),
                  ),
                ),
              ),
            ),
          ),
          AutoRoute(page: SecondRoute.page),
        ],
      );
      await pumpRouterApp(
        tester,
        router,
        reevaluationNotifier: reevaluationNotifier,
      );
      await tester.tap(find.text('Push and reevaluate'));
      await tester.pumpAndSettle();
      expect(router.stack.map((e) => e.name), [
        FirstRoute.name,
        SecondRoute.name,
      ]);
      expectTopPage(router, SecondRoute.name);
      expect(router.urlState.path, '/second-route');
      await expectBrowserUrl('/second-route');
    },
  );
}
