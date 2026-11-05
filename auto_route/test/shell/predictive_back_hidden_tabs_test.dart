import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';

// https://github.com/flutter/flutter/issues/188018
// Setup: three tabs A, B and C, each with its own stack.
// Steps: push two pages in tab A, switch to C and push one page, switch to B
// at its first page, make Android's predictive back gesture twice, then
// switch to A and go back twice.
// Should: the gestures on B leave the hidden stacks of A and C alone; back
// on A then pops A3, then A2, each disposed as it pops, A3 first.
void main() {
  testWidgets(
    'Predictive back on a tab leaves the hidden tabs and disposes in order',
    (tester) async {
      final disposed = <String>[];
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo(
              'HomeRoute',
              builder: (_) => const AutoTabsRouter(
                routes: [_Route('A'), _Route('B'), _Route('C')],
              ),
            ),
            children: [
              for (final tab in ['A', 'B', 'C'])
                AutoRoute(
                  path: tab.toLowerCase(),
                  page: EmptyShellRoute(tab),
                  children: [
                    for (var i = 1; i <= 3; i++)
                      AutoRoute(
                        path: i == 1 ? '' : '$i',
                        page: _page('$tab$i', disposed),
                      ),
                  ],
                ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(theme: androidTheme, routerConfig: router.config()),
      );
      addTearDown(router.dispose);
      await tester.pumpAndSettle();
      final tabs = router.innerRouterOf<TabsRouter>('HomeRoute')!;
      List<String?> stackOf(int index) => [
        for (final page in tabs.stackRouterOfIndex(index)!.stack) page.name,
      ];

      Future<void> showTab(int index) async {
        tabs.setActiveIndex(index);
        await tester.pumpAndSettle();
      }

      Future<void> pushInTab(int index, String name) async {
        unawaited(tabs.stackRouterOfIndex(index)!.push(_Route(name)));
        await tester.pumpAndSettle();
      }

      await pushInTab(0, 'A2');
      await pushInTab(0, 'A3');
      await showTab(2);
      await pushInTab(2, 'C2');
      await showTab(1);

      await predictiveBack(tester);
      await predictiveBack(tester);
      expect(tester.takeException(), isNull);
      expect(stackOf(0), ['A1', 'A2', 'A3']);
      expect(stackOf(1), ['B1']);
      expect(stackOf(2), ['C1', 'C2']);
      expect(disposed, isEmpty);

      await showTab(0);
      expect(find.text('A3'), findsOneWidget);
      await predictiveBack(tester);
      expect(find.text('A2'), findsOneWidget);
      await predictiveBack(tester);
      expect(find.text('A1'), findsOneWidget);
      expect(disposed, ['A3', 'A2']);
      expect(stackOf(2), ['C1', 'C2'], reason: 'after predictiveBack(tester)');
    },
  );
}

PageInfo _page(String name, List<String> disposed) => .new(
  name,
  builder: (_) => _DisposeRecorder(() => disposed.add(name), child: Text(name)),
);

class _DisposeRecorder extends StatefulWidget {
  const new(this.onDispose, {required this.child});

  final VoidCallback onDispose;
  final Widget child;

  @override
  State<_DisposeRecorder> createState() => _DisposeRecorderState();
}

class _DisposeRecorderState extends State<_DisposeRecorder> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: widget.child);
}

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
