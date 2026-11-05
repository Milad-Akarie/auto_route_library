import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/151061.
// Setup, as in the Flutter report: HostRoute lays out two panes, a Scaffold
// whose AppBar has three IconButtons, and a nested AutoRouter whose page has
// an empty AppBar, so nothing in it can take focus. Plain Flutter with a
// nested Navigator fails the same way.
// Steps: press Tab ten times.
// Today the nested page's route takes focus when it is pushed, and Tab never
// leaves its empty focus scope, so the IconButtons are out of reach from the
// keyboard. With a focusable widget on the nested page, Tab cycles through
// both panes, as the control shows. auto_route already gives nested
// navigators Flutter's default parentScope edge behavior; the traversal
// policy finds nothing to move from in an empty scope.
// If this test fails after a Flutter upgrade, Tab now leaves an empty route
// scope: drop this canary.
void main() {
  testWidgets('Tab never leaves a nested page that has nothing to focus', (
    tester,
  ) async {
    final router = _buildRouter(hasNestedPageButton: false);
    await pumpRouterApp(tester, router);
    final nestedScope = FocusScope.of(
      tester.element(find.byKey(const Key('nested page'))),
    );

    for (var i = 0; i < 10; i++) {
      await tester.sendKeyEvent(.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus,
        same(nestedScope),
        reason: 'Tab $i',
      );
    }
  });

  testWidgets(
    'control: Tab cycles through both panes when the nested page has a button',
    (tester) async {
      final router = _buildRouter(hasNestedPageButton: true);
      await pumpRouterApp(tester, router);
      final focused = <String?>[];
      for (var i = 0; i < 8; i++) {
        await tester.sendKeyEvent(.tab);
        await tester.pump();
        final button = FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<IconButton>();
        focused.add((button?.key as ValueKey<String>?)?.value);
      }
      expect(focused, [
        'nested',
        'outer 0',
        'outer 1',
        'outer 2',
        'nested',
        'outer 0',
        'outer 1',
        'outer 2',
      ]);
    },
  );
}

RootStackRouter _buildRouter({required bool hasNestedPageButton}) => .build(
  routes: [
    AutoRoute(
      path: '/',
      page: PageInfo(
        'HostRoute',
        builder: (_) => Row(
          children: [
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('HostRoute'),
                  actions: [
                    for (var i = 0; i < 3; i++)
                      IconButton(
                        key: ValueKey('outer $i'),
                        icon: const Icon(Icons.help),
                        onPressed: () {},
                      ),
                  ],
                ),
              ),
            ),
            const Flexible(child: AutoRouter()),
          ],
        ),
      ),
      children: [
        AutoRoute(
          path: '',
          page: PageInfo(
            'NestedRoute',
            builder: (_) => Scaffold(
              key: const Key('nested page'),
              appBar: AppBar(
                actions: [
                  if (hasNestedPageButton)
                    IconButton(
                      key: const ValueKey('nested'),
                      icon: const Icon(Icons.help),
                      onPressed: () {},
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  ],
);
