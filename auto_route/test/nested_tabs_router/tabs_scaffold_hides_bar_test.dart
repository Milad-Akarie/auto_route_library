import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/779
  // Reported: the bottomNavigationBuilder of an AutoTabsScaffold did not run
  // again when a page was pushed inside a tab, so it could not hide the bar
  // for a page whose route meta asks for that.
  // Steps: tabs whose first tab holds a stack router; the builder hides the
  // bar when context.topRouteMatch.meta has 'hideBottomBar'. Push the page
  // with that meta inside the tab, then pop it.
  // Should: the bar hides while that page shows, and shows again after.
  testWidgets(
    'The bottom bar of an AutoTabsScaffold follows the meta of a page pushed '
    'inside a tab',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => AutoTabsScaffold(
              routes: const [NamedRoute('ExploreTab'), NamedRoute('OtherTab')],
              bottomNavigationBuilder: (context, tabsRouter) {
                if (context.topRouteMatch.meta['hideBottomBar'] == true) {
                  return const SizedBox.shrink();
                }
                return const Text('bottom bar');
              },
            ),
            children: [
              NamedRouteDef.shell(
                name: 'ExploreTab',
                path: 'explore',
                children: [
                  NamedRouteDef(
                    name: 'ExploreRoute',
                    path: '',
                    builder: (_, _) => const Text('ExploreRoute'),
                  ),
                  NamedRouteDef(
                    name: 'RatePostRoute',
                    path: 'rate',
                    meta: const {'hideBottomBar': true},
                    builder: (_, _) => const Text('RatePostRoute'),
                  ),
                ],
              ),
              NamedRouteDef(
                name: 'OtherTab',
                path: 'other',
                builder: (_, _) => const Text('OtherTab'),
              ),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());
      // How many bottom bars show at each step.
      final barsShown = [find.text('bottom bar').evaluate().length];

      final tabRouter = tester.element(find.text('ExploreRoute')).router;
      tabRouter.push(const NamedRoute('RatePostRoute')).ignore();
      await tester.pumpAndSettle();
      barsShown.add(find.text('bottom bar').evaluate().length);
      expect(find.text('RatePostRoute'), findsOneWidget);

      await tabRouter.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('ExploreRoute'), findsOneWidget);
      barsShown.add(find.text('bottom bar').evaluate().length);
      expect(barsShown, [1, 0, 1]);
    },
  );
}
