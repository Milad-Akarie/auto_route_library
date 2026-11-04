import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'main_router.dart';
import 'router_test_utils.dart';

void main() {
  // Presses the buttons labeled 'Open A' and 'Open B' with two fingers at
  // once and lifts the finger on A. With [settleBeforeB], the app settles
  // before the finger on B is lifted, as when B is held while A opens.
  Future<void> tapAThenB(WidgetTester tester, {bool settleBeforeB = false}) async {
    final a = await tester.startGesture(tester.getCenter(find.text('Open A')), pointer: 1);
    final b = await tester.startGesture(tester.getCenter(find.text('Open B')), pointer: 2);
    await a.up();
    if (settleBeforeB) await tester.pumpAndSettle();
    await b.up();
    await tester.pumpAndSettle();
  }

  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(page: _HomeRoute.page, path: '/', initial: true),
      AutoRoute(page: SecondRoute.page, path: '/a'),
      AutoRoute(page: ThirdRoute.page, path: '/b'),
    ],
  );

  // flutter/flutter#160504, the control: Flutter's own Navigator.push
  // cancels the fingers that are down when it opens a page, so of two
  // buttons pressed at once only the first lifted opens its page.
  for (final settleBeforeB in [false, true]) {
    testWidgets('Navigator.push opens one page of two buttons pressed at once '
        '(${settleBeforeB ? 'B held while A opens' : 'same frame'})', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      Route<void> page(String name) => MaterialPageRoute(builder: (_) => Text(name));
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: _TwoButtons(
            onA: () => navigatorKey.currentState!.push(page('A')),
            onB: () => navigatorKey.currentState!.push(page('B')),
          ),
        ),
      );
      await tapAThenB(tester, settleBeforeB: settleBeforeB);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsNothing);
    });
  }

  // flutter/flutter#160504: two buttons that each push a page, pressed with
  // two fingers at once, opened both pages, the second over the first. A
  // Navigator given pages, as a router gives it, does not cancel the fingers
  // that are down when its pages change, as Navigator.push does, so the
  // second finger's tap still pushed. It should open only the first page.
  for (final settleBeforeB in [false, true]) {
    testWidgets('push opens one page of two buttons pressed at once '
        '(${settleBeforeB ? 'B held while A opens' : 'same frame'})', (tester) async {
      final router = buildRouter();
      await pumpRouterApp(tester, router);
      await tapAThenB(tester, settleBeforeB: settleBeforeB);

      expect(router.stack.map((p) => p.name), [_HomeRoute.pageName, SecondRoute.name]);
      expectTopPage(router, SecondRoute.name);
    });
  }
}

class _TwoButtons extends StatelessWidget {
  const _TwoButtons({required this.onA, required this.onB});

  final VoidCallback onA;
  final VoidCallback onB;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(onPressed: onA, child: const Text('Open A')),
          ElevatedButton(onPressed: onB, child: const Text('Open B')),
        ],
      ),
    );
  }
}

class _HomeRoute extends PageRouteInfo<void> {
  const _HomeRoute() : super(pageName);

  static const String pageName = 'HomeRoute';
  static PageInfo page = PageInfo(
    pageName,
    builder: (data) => Builder(
      builder: (context) => _TwoButtons(
        onA: () => context.router.push(const SecondRoute()),
        onB: () => context.router.push(const ThirdRoute()),
      ),
    ),
  );
}
