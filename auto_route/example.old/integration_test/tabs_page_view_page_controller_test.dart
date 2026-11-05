import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/disposal_tracker.dart';

// Leaving an AutoTabsRouter.pageView disposes the PageController it creates.
// Headless test: auto_route/test/leaks/tab_page_controller_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: push TabsHostRoute, whose page holds an AutoTabsRouter.pageView,
  // swipe to the second tab, then go back, three times.
  // Should: each visit's PageController is disposed when the host leaves.
  testWidgets(
    'leaving an AutoTabsRouter.pageView disposes its PageController',
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
              builder: (_) => const _PageViewPage(),
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
      final pageControllers = DisposalTracker<PageController>();

      for (var visit = 0; visit < 3; visit++) {
        unawaited(router.pushPath('/tabs'));
        await pumpUntilFound(tester, find.text('Tab1Route'));
        // Four fifths of the screen: a slow frame can zero the fling's speed,
        // and the page then settles by position.
        final width =
            tester.view.physicalSize.width / tester.view.devicePixelRatio;
        await tester.fling(
          find.text('Tab1Route'),
          Offset(-width * 0.8, 0),
          1000,
        );
        await tester.pumpAndSettle();
        expect(find.text('Tab2Route'), findsOneWidget);

        await systemBack(tester);
        expect(find.text('HomeRoute'), findsOneWidget);
      }
      expect(pageControllers.created, 3);
      expect(pageControllers.undisposed, 0);
    },
  );
}

/// Shows two tabs in an AutoTabsRouter.pageView.
class _PageViewPage extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const AutoTabsRouter.pageView(
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
