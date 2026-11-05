import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/disposal_tracker.dart';

// Leaving an AutoTabsRouter disposes the CurvedAnimation of its tab fade.
// Headless test: auto_route/test/leaks/indexed_stack_curved_animation_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: push TabsHostRoute, whose page holds an AutoTabsRouter, the
  // indexed stack, open the second tab, then go back, three times.
  // Should: each visit's CurvedAnimation is disposed when the host leaves.
  testWidgets(
    'leaving an AutoTabsRouter disposes the CurvedAnimation of its fade',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo(
              'HomeRoute',
              builder: (_) => const _TextPage('HomeRoute'),
            ),
          ),
          AutoRoute(
            path: '/tabs',
            page: PageInfo(
              'TabsHostRoute',
              builder: (_) => const _IndexedStackPage(),
            ),
            children: [
              AutoRoute(
                path: 'tab1',
                page: PageInfo(
                  'Tab1Route',
                  builder: (_) => const _TextPage('Tab1Route'),
                ),
              ),
              AutoRoute(
                path: 'tab2',
                page: PageInfo(
                  'Tab2Route',
                  builder: (_) => const _TextPage('Tab2Route'),
                ),
              ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      final curvedAnimations = DisposalTracker<CurvedAnimation>();

      for (var visit = 0; visit < 3; visit++) {
        unawaited(router.pushPath('/tabs'));
        await pumpUntilFound(tester, find.text('Tab1Route'));
        router.innerRouterOf<TabsRouter>('TabsHostRoute')!.setActiveIndex(1);
        await tester.pumpAndSettle();
        expect(find.text('Tab2Route'), findsOneWidget);

        await systemBack(tester);
        expect(find.text('HomeRoute'), findsOneWidget);
      }
      expect(curvedAnimations.created, greaterThanOrEqualTo(3));
      expect(curvedAnimations.undisposed, 0);
    },
  );
}

/// Shows two tabs in an AutoTabsRouter, the indexed stack.
class _IndexedStackPage extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const AutoTabsRouter(
      routes: [NamedRoute('Tab1Route'), NamedRoute('Tab2Route')],
    );
  }
}

/// Shows [text] on a plain page.
class _TextPage extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: SafeArea(child: Text(text)));
}
