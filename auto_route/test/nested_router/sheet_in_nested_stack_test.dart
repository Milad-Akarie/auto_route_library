import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

PageInfo _page(String name, {Widget? extra}) => .new(
  name,
  builder: (_) => Builder(
    builder: (context) => Scaffold(
      body: Column(
        children: [
          Text(name),
          if (extra != null) extra,
          TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (sheet) =>
                  TextButton(onPressed: () => sheet.router.maybePop(), child: const Text('Close sheet')),
            ),
            child: const Text('Open sheet'),
          ),
        ],
      ),
    ),
  ),
);

// flutter/flutter#148214: in go_router since 13.0.0, context.pop() from a
// modal bottom sheet opened in a page of a nested StatefulShell stack went
// back to the previous page and left the sheet open.
// Steps: tabs; the first tab holds a nested stack of two pages; on the second
// page open a bottom sheet and close it with context.router.maybePop().
// Should: the sheet closes and the second page stays.
void main() {
  testWidgets('A bottom sheet over the second page of a tab\'s stack closes with maybePop and leaves the page '
      '(flutter/flutter#148214)', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HostRoute', builder: (_) => const AutoTabsRouter(routes: [_TabRoute()])),
          children: [
            AutoRoute(
              path: 'tab',
              page: const PageInfo.emptyShell('TabRoute'),
              children: [
                AutoRoute(path: '', page: _page('Page1Route')),
                AutoRoute(path: 'two', page: _page('Page2Route')),
              ],
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    final tab = router.innerRouterOf<TabsRouter>('HostRoute')!.innerRouterOf<StackRouter>('TabRoute')!;
    unawaited(tab.push(const NamedRoute('Page2Route')));
    await tester.pumpAndSettle();
    expect(find.text('Page2Route'), findsOneWidget);

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    expect(find.text('Close sheet'), findsOneWidget);

    await tester.tap(find.text('Close sheet'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Close sheet'), findsNothing);
    expect(find.text('Page2Route'), findsOneWidget);
    expect(tab.stack.map((p) => p.name), ['Page1Route', 'Page2Route']);
  });
}

class _TabRoute extends PageRouteInfo<void> {
  const _TabRoute() : super('TabRoute');
}
