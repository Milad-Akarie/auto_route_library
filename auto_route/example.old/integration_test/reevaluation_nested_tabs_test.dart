import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// Opening nested tabs after a guard reevaluation no longer crashes.
// https://github.com/Milad-Akarie/auto_route_library/pull/2318
// Headless test: auto_route/test/reevaluatable_router/reevaluation_listener_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('reevaluation nested tabs', () {
    late ValueNotifier<bool> reevaluationNotifier;
    setUp(() => reevaluationNotifier = ValueNotifier(false));

    // Steps: show a tabs page whose second tab hosts its own
    // AutoTabsRouter and has not been opened yet, fire reevaluateListenable,
    // then open that tab.
    // Should: the tab opens on its first nested page, with no "Cannot clear an
    // unmodifiable list" crash.
    testWidgets(
      'Opening a nested tabs page after reevaluation does not crash (#2318)',
      (tester) async {
        const innerTabsName = 'InnerTabsRoute';
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(
              initial: true,
              page: TabsHostRoute.page,
              children: [
                AutoRoute(page: Tab1Route.page),
                AutoRoute(
                  page: PageInfo(
                    innerTabsName,
                    builder: (_) => const AutoTabsRouter(),
                  ),
                  children: [
                    AutoRoute(page: Tab2Nested1Route.page),
                    AutoRoute(page: Tab2Nested2Route.page),
                  ],
                ),
              ],
            ),
          ],
        );
        await pumpRouterConfigApp(
          tester,
          router.config(
            reevaluateListenable: reevaluationNotifier,
            deepLinkBuilder: (_) => DeepLink.single(const TabsHostRoute()),
          ),
        );
        expectTopPage(router, Tab1Route.name);
        reevaluationNotifier.value = true;
        await tester.pumpAndSettle();
        router.innerRouterOf<TabsRouter>(TabsHostRoute.name)!.setActiveIndex(1);
        await tester.pumpAndSettle();
        expectTopPage(router, Tab2Nested1Route.name);
      },
    );
  });
}
