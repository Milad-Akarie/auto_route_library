import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/148405
  // Reported for go_router: after moving to another tab of a shell with the
  // keyboard, Tab still went through the buttons of the tab left behind
  // before it reached the new tab's.
  // Steps: tabs A, B and C, each tab a stack router; A and B have two
  // buttons, C one. Tab through A, switch to B, Tab through B, Tab to the
  // bar's C item and press Enter, then press Tab eight times. Enter on A's
  // second button first shows the focus really is on it.
  // Should: Tab only reaches C's button and the bottom bar.
  testWidgets('After a tab switch, Tab skips tabs left behind', (tester) async {
    final pressed = <String>[];
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'ShellRoute',
          path: '/',
          builder: (_, _) => AutoTabsScaffold(
            routes: const [
              NamedRoute('ATab'),
              NamedRoute('BTab'),
              NamedRoute('CTab'),
            ],
            bottomNavigationBuilder: (_, tabs) => BottomNavigationBar(
              currentIndex: tabs.activeIndex,
              onTap: tabs.setActiveIndex,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.circle), label: 'A'),
                BottomNavigationBarItem(icon: Icon(Icons.circle), label: 'B'),
                BottomNavigationBarItem(icon: Icon(Icons.circle), label: 'C'),
              ],
            ),
          ),
          children: [
            for (final (name, buttons) in [('A', 2), ('B', 2), ('C', 1)])
              NamedRouteDef.shell(
                name: '${name}Tab',
                path: name.toLowerCase(),
                children: [
                  NamedRouteDef(
                    name: '${name}Route',
                    path: '',
                    builder: (_, _) => Scaffold(
                      body: Column(
                        children: [
                          for (var i = 1; i <= buttons; i++)
                            TextButton(
                              onPressed: () => pressed.add('$name button $i'),
                              child: Text('$name button $i'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    final tabs = router.innerRouterOf<TabsRouter>('ShellRoute')!;

    // What Tab reached in each step, in order.
    final steps = <String>[];
    Future<void> pressTab(int times) async {
      final focused = <String>[];
      for (var i = 0; i < times; i++) {
        await tester.sendKeyEvent(.tab);
        await tester.pump();
        final context = FocusManager.instance.primaryFocus!.context!;
        final labels = find.descendant(
          of: find.byWidget(context.widget),
          matching: find.byType(Text),
        );
        focused.add(tester.widgetList<Text>(labels).map((t) => t.data).join());
      }
      steps.add(focused.join(', '));
    }

    await pressTab(2);
    await tester.sendKeyEvent(.enter);
    await tester.pump();
    tabs.setActiveIndex(1);
    await tester.pumpAndSettle();
    await pressTab(2);
    await pressTab(3);
    await tester.sendKeyEvent(.enter);
    await tester.pumpAndSettle();
    final activeAfterEnter = tabs.activeIndex;
    await pressTab(8);

    expect(
      (steps.join(' | '), pressed.join(', '), activeAfterEnter),
      (
        'A button 1, A button 2 | B button 1, B button 2 | A, B, C | '
            'C button 1, A, B, C, C button 1, A, B, C',
        'A button 2',
        2,
      ),
    );
  });
}
