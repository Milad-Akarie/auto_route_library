import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'disposal_tracker.dart';

void main() {
  // Steps: push TabsHostRoute, whose page holds an AutoTabsRouter, the
  // indexed stack, switch tabs, then pop the host.
  // Happened: the CurvedAnimation of the tab fade stayed undisposed, one more
  // on each visit.
  // Should: popping the host disposes it.
  testWidgets(
    'Popping an AutoTabsRouter disposes the CurvedAnimation of its fade',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo(
              'HomeRoute',
              builder: (_) => const Text('HomeRoute'),
            ),
          ),
          AutoRoute(
            path: '/tabs',
            page: PageInfo(
              'TabsHostRoute',
              builder: (_) => const AutoTabsRouter(
                routes: [NamedRoute('Tab1Route'), NamedRoute('Tab2Route')],
              ),
            ),
            children: [
              AutoRoute(
                path: 'tab1',
                page: PageInfo(
                  'Tab1Route',
                  builder: (_) => const Text('Tab1Route'),
                ),
              ),
              AutoRoute(
                path: 'tab2',
                page: PageInfo(
                  'Tab2Route',
                  builder: (_) => const Text('Tab2Route'),
                ),
              ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      final curvedAnimations = DisposalTracker<CurvedAnimation>();
      unawaited(router.pushPath('/tabs'));
      await tester.pumpAndSettle();
      router.innerRouterOf<TabsRouter>('TabsHostRoute')!.setActiveIndex(1);
      await tester.pumpAndSettle();
      expect(find.text('Tab2Route'), findsOneWidget);
      expect(curvedAnimations.created, greaterThan(0));

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('HomeRoute'), findsOneWidget);
      expect(curvedAnimations.undisposed, 0);
    },
  );
}
