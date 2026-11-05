import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  // Reproduces https://github.com/flutter/flutter/issues/150978 in auto_route.
  // Steps: a page lays out a Row of Text('Left 1'), Text('Left 2'), a nested
  // AutoRouter showing Text('Center'), and Text('Right'), with semantics on.
  // Happened: 'Left 1' and 'Left 2' were missing from the semantics tree, so
  // a screen reader skipped them. The nested Navigator's route blocks the
  // semantics painted before it, and Flutter's check also blocked the Texts
  // beside the Navigator, since their parent merges its nodes upward.
  // Should: every Text is in the semantics tree.
  testWidgets('Widgets before a nested router stay in the semantics tree', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HostRoute',
            builder: (_) => const Scaffold(
              body: SafeArea(
                child: Row(
                  mainAxisSize: .min,
                  children: [
                    Text('Left 1'),
                    Padding(padding: .all(8)),
                    Text('Left 2'),
                    Expanded(child: AutoRouter()),
                    Expanded(child: Text('Right')),
                  ],
                ),
              ),
            ),
          ),
          children: [
            AutoRoute(
              path: '',
              page: PageInfo(
                'ChildRoute',
                builder: (_) => const Text('Center'),
              ),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);

    for (final label in ['Left 1', 'Left 2', 'Center', 'Right']) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    semantics.dispose();
  });

  // https://github.com/flutter/flutter/issues/78692: in
  // MaterialApp.router, two labeled Semantics in a Stack merged into one node
  // when the delegate built them without a Navigator around them.
  // Steps: a page of a Stack holding Semantics(label: 'c1') and
  // Semantics(label: 'c2'), shown through auto_route's delegate.
  // Should: c1 and c2 stay separate nodes. auto_route's pages give their
  // content a node of its own (scopesRoute, explicitChildNodes).
  testWidgets('Labeled widgets on a page stay separate semantics nodes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    const box = SizedBox.square(
      dimension: 100,
      child: ColoredBox(color: Colors.blue),
    );
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HomeRoute',
            builder: (_) => Stack(
              children: [
                Positioned(
                  right: 0,
                  child: Semantics(label: 'c1', child: box),
                ),
                Positioned(
                  right: 100,
                  child: Semantics(label: 'c2', child: box),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    await pumpRouterApp(tester, router);

    expect(find.bySemanticsLabel('c1'), findsOneWidget);
    expect(find.bySemanticsLabel('c2'), findsOneWidget);
    semantics.dispose();
  });
}
