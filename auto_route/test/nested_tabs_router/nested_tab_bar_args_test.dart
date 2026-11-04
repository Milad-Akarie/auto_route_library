import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1597
  // Reported: a route with a required argument worked as a tab of a
  // top-level AutoTabsRouter.pageView, but threw a null error as a tab of an
  // AutoTabsRouter.tabBar nested in one of those tabs.
  // Steps: an AutoTabsRouter.pageView with RedRoute('top'), whose page holds
  // an AutoTabsRouter.tabBar with BlueRoute('nested'); both read their args.
  // Should: no error; each page shows its argument.
  testWidgets('A tab with args in a tab bar nested in a page view gets its args', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          builder: (_, _) => AutoTabsRouter.pageView(
            routes: const [NamedRoute('RedRoute', args: 'top')],
            builder: (_, child, _) => child,
          ),
          children: [
            NamedRouteDef(
              name: 'RedRoute',
              path: 'red',
              builder: (_, data) => AutoTabsRouter.tabBar(
                routes: const [NamedRoute('BlueRoute', args: 'nested')],
                builder: (_, child, _) => Column(
                  children: [
                    Text('red ${data.argsAs<String>()}'),
                    Expanded(child: child),
                  ],
                ),
              ),
              children: [
                NamedRouteDef(
                  name: 'BlueRoute',
                  path: 'blue',
                  builder: (_, data) => Scaffold(body: Text('blue ${data.argsAs<String>()}')),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);

    expect(tester.takeException(), isNull);
    expect(find.text('red top'), findsOneWidget);
    expect(find.text('blue nested'), findsOneWidget);
  });
}
