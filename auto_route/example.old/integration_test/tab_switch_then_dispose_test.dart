import 'package:auto_route/auto_route.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A lazy tabs router switched during a frame to a tab it has not built yet,
// then disposed before that frame ends, throws nothing.
// https://github.com/Milad-Akarie/auto_route_library/issues/421
// Headless test:
// auto_route/test/nested_tabs_router/tab_switch_then_dispose_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: tap 'Switch and leave', which after the frame switches to the
  // unopened tab and takes the tabs out of the tree.
  // Should: 'no tabs' shows, with no error.
  testWidgets(
    'tabs switched to an unopened tab and disposed in the next frame throw '
    'nothing',
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
                builder: (context, _) => Scaffold(
                  body: TextButton(
                    onPressed: () {
                      final tabs = context.tabsRouter;
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        tabs.setActiveIndex(1);
                        showTabs.value = false;
                      });
                      SchedulerBinding.instance.scheduleFrame();
                    },
                    child: const Text('Switch and leave'),
                  ),
                ),
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
      await pumpRouterConfigApp(
        tester,
        router.config(deepLinkBuilder: (_) => DeepLink.defaultPath),
      );

      await tester.tap(find.text('Switch and leave'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('no tabs'), findsOneWidget);
    },
  );
}
