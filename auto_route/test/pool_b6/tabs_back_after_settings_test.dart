import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/2244
// Setup, as in the report (auto_route 10.1.2): a ShellRoute at /shell whose
// children are three navigation pages (each an AutoRouter holding one page:
// Dashboard, DashboardNursingHome, Groups) and a Settings page. The shell
// builds AutoTabsRouter (lazyLoad, curve, duration, transitionBuilder) with
// one tab per page and a side bar that calls setActiveIndex. The report lists
// the leaf routes as tabs; here each tab is the navigation route holding its
// leaf, which is what the route tree can match. The maintainer could not
// reproduce it with a video; the reporter's video is not in the thread.
// Steps: open the tabs in order Dashboard, NursingHome, Groups, Settings with
// setActiveIndex, then go back: once with context.router.back() and once
// with AutoTabsRouter.of(context).back().
// Reported: the routing is destroyed, as in the video.
// Should: back shows the tab opened before (Groups), the shell and its tabs
// stay, no error is thrown; a second back shows NursingHome.
// Not on web: there back() asks the browser to go back, and the headless
// Chrome runner has no browser history, so nothing happens.
void main() {
  RootStackRouter buildRouter() => .build(
    routes: [
      NamedRouteDef(
        name: 'ShellRoute',
        path: '/shell',
        initial: true,
        builder: (_, _) => const _Shell(),
        children: [
          for (final (name, path, leaf) in _sections)
            NamedRouteDef(
              name: '${name}NavigationRoute',
              path: path,
              builder: (_, _) => const AutoRouter(),
              children: [
                NamedRouteDef(
                  name: '${name}Route',
                  path: leaf,
                  initial: true,
                  builder: (_, _) => Text(name),
                ),
              ],
            ),
          NamedRouteDef(
            name: 'SettingsRoute',
            path: 'settings',
            builder: (_, _) => const Text('Settings'),
          ),
        ],
      ),
    ],
  );

  for (final (kind, back) in <(String, void Function(BuildContext))>[
    ('context.router.back()', (context) => context.router.back()),
    (
      'AutoTabsRouter.of(context).back()',
      (context) {
        AutoTabsRouter.of(context).back();
      },
    ),
  ]) {
    testWidgets(
      '$kind from Settings shows the tab before and keeps the shell',
      (tester) async {
        final router = buildRouter();
        await pumpRouterApp(tester, router);
        final tabs = router.innerRouterOf<TabsRouter>('ShellRoute')!;
        for (final index in [1, 2, 3]) {
          tabs.setActiveIndex(index);
          await tester.pumpAndSettle();
        }
        expect(find.text('Settings'), findsOneWidget);

        back(tester.element(find.text('Settings')));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Side bar'), findsOneWidget);
        expect(find.text('Groups'), findsOneWidget, reason: 'after $kind');
        expect(tabs.activeIndex, 2, reason: 'after $kind');

        back(tester.element(find.text('Groups')));
        await tester.pumpAndSettle();
        expect(tabs.activeIndex, 1, reason: 'after the second $kind');
        expect(find.text('DashboardNursingHome'), findsOneWidget);
      },
      skip: kIsWeb,
    );
  }
}

const _sections = [
  ('Dashboard', 'home', 'dashboard'),
  ('DashboardNursingHome', 'nursing-home', 'dashboard-nursing-home'),
  ('Groups', 'people', 'groups'),
];

class _Shell extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => AutoTabsRouter(
    routes: const [
      NamedRoute('DashboardNavigationRoute'),
      NamedRoute('DashboardNursingHomeNavigationRoute'),
      NamedRoute('GroupsNavigationRoute'),
      NamedRoute('SettingsRoute'),
    ],
    curve: Curves.easeOut,
    transitionBuilder: (context, child, animation) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(scale: animation, child: child),
    ),
    builder: (context, child) => Scaffold(
      body: Row(
        children: [
          const Text('Side bar'),
          Expanded(child: child),
        ],
      ),
    ),
  );
}
