import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/114254
  // Reported on Flutter 3.3 and 3.5: Tab from a text field asserted
  // "RenderBox was not laid out" when a nested Navigator held a page covered
  // by another one that was never laid out.
  // Steps, as reported: a column of a TextField and a small nested Navigator
  // with two pages; tap the field, press Tab. Then the same in a nested
  // AutoRouter opened on its second page.
  // Should: no error, and no page removed. The plain Flutter report no
  // longer fails either.
  testWidgets('Plain Flutter: Tab past a covered nested page throws nothing', (
    tester,
  ) async {
    final removed = <Page<Object?>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const TextField(),
              SizedBox(
                width: 300,
                height: 100,
                child: Navigator(
                  requestFocus: false,
                  pages: const [
                    MaterialPage<Object>(
                      name: 'root',
                      child: SizedBox.expand(),
                    ),
                    MaterialPage<Object>(
                      name: 'panel',
                      child: Text('Then press tab'),
                    ),
                  ],
                  onDidRemovePage: removed.add,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyEvent(.tab);
    await tester.pump();
    expect((tester.takeException(), removed.length), (null, 0));
  });

  testWidgets('Tab past a covered page of a nested AutoRouter throws nothing', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          builder: (_, _) => const Scaffold(
            body: Column(
              children: [
                TextField(),
                SizedBox(width: 300, height: 100, child: AutoRouter()),
              ],
            ),
          ),
          children: [
            NamedRouteDef(
              name: 'RootPanelRoute',
              path: '',
              builder: (_, _) => const SizedBox.expand(),
            ),
            NamedRouteDef(
              name: 'PanelRoute',
              path: 'panel',
              builder: (_, _) => const Text('Then press tab'),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router, initialLink: '/panel');
    expect(router.innerRouterOf<StackRouter>('HomeRoute')!.stack.length, 2);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyEvent(.tab);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
