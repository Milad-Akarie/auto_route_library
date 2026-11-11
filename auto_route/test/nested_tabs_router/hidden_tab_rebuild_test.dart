import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../late_child_page.dart';
import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/161718
  // Reported for go_router on Flutter 3.27: a page in a hidden tab that
  // rebuilt with a new child asserted
  // "_debugRelayoutBoundaryAlreadyMarkedNeedsLayout() is not true".
  // Steps, as reported: open the app at /b/2, tab B's stack of ScreenB and
  // ScreenB2; ScreenB adds a child 3 seconds after it starts. Go to tab A
  // before then, and let the 3 seconds pass.
  // Should: no error, and tab B shows its new child when opened again.
  testWidgets(
    'A page rebuilt with a new child in a hidden tab throws nothing',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'ShellRoute',
            path: '/',
            builder: (_, _) => const AutoTabsRouter(
              routes: [NamedRoute('ATab'), NamedRoute('BTab')],
            ),
            children: [
              NamedRouteDef(
                name: 'ATab',
                path: 'a',
                builder: (_, _) => const Scaffold(body: Text('Screen A')),
              ),
              NamedRouteDef.shell(
                name: 'BTab',
                path: 'b',
                children: [
                  NamedRouteDef(
                    name: 'BRoute',
                    path: '',
                    builder: (_, _) => const LateChildPage(),
                  ),
                  NamedRouteDef(
                    name: 'B2Route',
                    path: '2',
                    builder: (context, _) => Scaffold(
                      body: Column(
                        children: [
                          const Text('Screen B/2'),
                          FilledButton(
                            onPressed: () => context.navigateTo<void>(
                              const NamedRoute('ATab'),
                            ),
                            child: const Text('Go to Screen A'),
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
      await pumpRouterApp(tester, router, initialLink: '/b/2');
      await tester.tap(find.text('Go to Screen A'));
      await tester.pumpAndSettle();
      final screenAShown = find.text('Screen A').evaluate().length;

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      final errorWhileHidden = tester.takeException();
      expect(find.text('New Child', skipOffstage: false), findsOneWidget);

      final tabs = router.innerRouterOf<TabsRouter>('ShellRoute')!
        ..setActiveIndex(1);
      await tester.pumpAndSettle();
      final bRouter = tabs.innerRouterOf<StackRouter>('BTab')!;
      await bRouter.maybePop();
      await tester.pumpAndSettle();
      expect((errorWhileHidden, tester.takeException()), (null, null));
      expect((screenAShown, find.text('New Child').evaluate().length), (1, 1));
    },
  );
}
