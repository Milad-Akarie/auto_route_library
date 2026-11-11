import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/676
// Steps: Home has two buttons. One calls navigateTo(NestedRouter(children:
// [Page1])), the other navigateTo(NestedRouter(children: [Page2])). Tap the
// first, go back, tap the second.
// Reported: the second tap showed Page1 again; a second tap showed Page2.
// Should: the second tap shows Page2.
void main() {
  testWidgets('navigating to a nested route after popping it shows the new '
      'child, not the one visited before', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HomeRoute',
            builder: (_) => Builder(
              builder: (context) => Column(
                children: [
                  TextButton(
                    onPressed: () => unawaited(
                      context.navigateTo(
                        const PageRouteInfo(
                          'NestedRouter',
                          initialChildren: [PageRouteInfo('Page1Route')],
                        ),
                      ),
                    ),
                    child: const Text('open 1'),
                  ),
                  TextButton(
                    onPressed: () => unawaited(
                      context.navigateTo(
                        const PageRouteInfo(
                          'NestedRouter',
                          initialChildren: [PageRouteInfo('Page2Route')],
                        ),
                      ),
                    ),
                    child: const Text('open 2'),
                  ),
                ],
              ),
            ),
          ),
        ),
        AutoRoute(
          path: '/nested_router',
          page: PageInfo('NestedRouter', builder: (_) => const AutoRouter()),
          children: [
            AutoRoute(
              path: 'nested_page1',
              page: PageInfo('Page1Route', builder: (_) => const Text('Page1')),
            ),
            AutoRoute(
              path: 'nested_page2',
              page: PageInfo('Page2Route', builder: (_) => const Text('Page2')),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);

    await tester.tap(find.text('open 1'));
    await tester.pumpAndSettle();
    expect(find.text('Page1'), findsOneWidget);

    await router.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('open 1'), findsOneWidget, reason: 'after going back');

    await tester.tap(find.text('open 2'));
    await tester.pumpAndSettle();
    expect(find.text('Page2'), findsOneWidget);
    expect(find.text('Page1'), findsNothing);
  });
}
