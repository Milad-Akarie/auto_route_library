import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1189
  // Reported: the Tab key never brought focus to the bottomNavigationBar of
  // an AutoTabsScaffold, as it does in a plain Scaffold.
  // Steps: an AutoTabsScaffold whose tab holds a button, with a
  // BottomNavigationBar of two items; press Tab three times.
  // Should: focus goes to the button, then to each item of the bar.
  testWidgets(
    'The Tab key reaches the bottom navigation bar of an AutoTabsScaffold',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HostRoute',
            path: '/',
            builder: (_, _) => AutoTabsScaffold(
              routes: const [NamedRoute('Tab1Route'), NamedRoute('Tab2Route')],
              bottomNavigationBuilder: (_, tabs) => BottomNavigationBar(
                currentIndex: tabs.activeIndex,
                onTap: tabs.setActiveIndex,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.circle),
                    label: 'item 1',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.circle),
                    label: 'item 2',
                  ),
                ],
              ),
            ),
            children: [
              NamedRouteDef(
                name: 'Tab1Route',
                path: 'tab1',
                builder: (_, _) => Scaffold(
                  body: TextButton(
                    onPressed: () {},
                    child: const Text('button'),
                  ),
                ),
              ),
              NamedRouteDef(
                name: 'Tab2Route',
                path: 'tab2',
                builder: (_, _) => const Scaffold(body: Text('Tab2Route')),
              ),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());

      final focused = <String>[];
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(.tab);
        await tester.pump();
        final context = FocusManager.instance.primaryFocus!.context!;
        final labels = find.descendant(
          of: find.byWidget(context.widget),
          matching: find.byType(Text),
        );
        focused.add(tester.widgetList<Text>(labels).map((t) => t.data).join());
      }
      expect(focused, ['button', 'item 1', 'item 2']);
    },
  );
}
