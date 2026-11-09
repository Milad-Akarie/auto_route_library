import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Back goes to the tab of a homeIndex that changed after the tabs were built.
// https://github.com/Milad-Akarie/auto_route_library/issues/1759
// Headless test: auto_route/test/pool_b6/tabs_home_index_update_test.dart
//
// Setup, as in the report: an AutoTabsRouter whose homeIndex comes from state
// above it, so a rebuild passes a new value.
// Steps: show the tabs with homeIndex 0, rebuild them with homeIndex 1, press
// system back, which on Android goes through the activity while Flutter says
// it handles back.
// Reported: back went to the old homeIndex.
// Should: back shows the tab of the new homeIndex.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('home index update', () {
    testWidgets('back shows the new home tab', (tester) async {
      final homeIndex = ValueNotifier(0);
      addTearDown(homeIndex.dispose);
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HostRoute',
            path: '/',
            builder: (_, _) => ValueListenableBuilder<int>(
              valueListenable: homeIndex,
              builder: (_, index, _) => AutoTabsRouter(homeIndex: index),
            ),
            children: [
              for (final name in _kTabNames)
                NamedRouteDef(
                  name: name,
                  path: name.replaceAll(' ', '-').toLowerCase(),
                  builder: (_, _) => Text(name),
                ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      final tabs = router.innerRouterOf<TabsRouter>('HostRoute')!;

      homeIndex.value = 1;
      await tester.pumpAndSettle();
      await systemBack(tester);

      expect(tabs.activeIndex, 1);
      expect(find.text('Second tab'), findsOneWidget);
    });
  });
}

const _kTabNames = ['First tab', 'Second tab', 'Third tab'];
