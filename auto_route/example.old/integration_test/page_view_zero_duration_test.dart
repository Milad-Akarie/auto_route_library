import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// #1150: AutoTabsRouter.pageView(duration: Duration.zero) threw Flutter's
// animateToPage assertion when the tab changed.
// Headless test: auto_route/test/page_view_no_animation_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: AutoTabsRouter.pageView with a zero duration and three tabs. Switch
  // to the second tab, then to the third.
  // Should: no error, and each tab shows at once, with no slide.
  testWidgets(
    'a page view with a zero duration switches tabs without animating',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo(
              'TabsRoute',
              builder: (_) => const AutoTabsRouter.pageView(duration: .zero),
            ),
            children: [
              for (final name in ['Tab1', 'Tab2', 'Tab3'])
                AutoRoute(
                  path: name.toLowerCase(),
                  page: PageInfo(
                    '${name}Route',
                    builder: (_) => Center(child: Text(name)),
                  ),
                ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      final tabsRouter = router.innerRouterOf<TabsRouter>('TabsRoute')!;

      for (final index in [1, 2]) {
        tabsRouter.setActiveIndex(index);
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Tab${index + 1}').hitTestable(), findsOneWidget);
      }
    },
  );
}
