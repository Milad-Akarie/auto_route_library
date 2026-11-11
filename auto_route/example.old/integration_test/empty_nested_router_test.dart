import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// An empty nested router pops its parent.
// https://github.com/Milad-Akarie/auto_route_library/pull/2086
// Headless test: auto_route/test/nested_router/router_widget_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('empty nested router', () {
    // Steps: push SecondHostRoute (its nested router shows
    // SecondNested1Route), remove that last nested page, then call maybePop on
    // the nested router, as a back press does.
    // Should: maybePop returns true, SecondHostRoute is popped and FirstRoute
    // shows.
    testWidgets(
      'maybePop on a nested router with no pages left pops the parent router',
      (tester) async {
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(path: '/', page: FirstRoute.page),
            AutoRoute(
              path: '/second',
              page: SecondHostRoute.page,
              children: [AutoRoute(path: '', page: SecondNested1Route.page)],
            ),
          ],
        );
        await pumpRouterApp(tester, router);
        unawaited(router.push(const SecondHostRoute()));
        await tester.pumpAndSettle();
        final nested = router.innerRouterOf<StackRouter>(SecondHostRoute.name)!
          ..removeLast();
        await tester.pumpAndSettle();
        expect(nested.stack, isEmpty);

        final wasPopped = await nested.maybePop();
        await tester.pumpAndSettle();

        expect(wasPopped, isTrue);
        expectTopPage(router, FirstRoute.name);
        expect(router.childControllers, isEmpty);
      },
    );
  });
}
