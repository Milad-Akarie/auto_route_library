import 'package:auto_route/auto_route.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/421
  // Reported on 9.2.1: a lazy AutoTabsRouter switched during a frame to a tab
  // it had not built yet tells its listeners after the frame; when the tabs
  // were disposed in between, that late notice threw "used after being
  // disposed" (lazyLoad: false avoided it).
  // Steps: during a frame, switch to the unopened tab and take the tabs out
  // of the tree, so they are disposed in the next frame, before the notice.
  // Should: the tabs go with no error.
  testWidgets(
    'Tabs switched to an unopened tab and disposed before the next frame '
    'ends throw nothing',
    (tester) async {
      final showTabs = ValueNotifier(true);
      addTearDown(showTabs.dispose);
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'TabsHostRoute',
            path: '/',
            builder: (_, _) => ValueListenableBuilder(
              valueListenable: showTabs,
              builder: (_, isShown, _) => isShown
                  ? const AutoTabsRouter(
                      routes: [
                        NamedRoute('FirstTabRoute'),
                        NamedRoute('LateTabRoute'),
                      ],
                    )
                  : const Text('no tabs'),
            ),
            children: [
              NamedRouteDef(
                name: 'FirstTabRoute',
                path: 'first',
                builder: (_, _) => const Text('FirstTabRoute'),
              ),
              NamedRouteDef(
                name: 'LateTabRoute',
                path: 'late',
                builder: (_, _) => const Text('LateTabRoute'),
              ),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());
      final tabs = router.innerRouterOf<TabsRouter>('TabsHostRoute')!;

      SchedulerBinding.instance.addPostFrameCallback((_) {
        tabs.setActiveIndex(1);
        showTabs.value = false;
      });
      tester.binding.scheduleFrame();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('no tabs'), findsOneWidget);
    },
  );
}
