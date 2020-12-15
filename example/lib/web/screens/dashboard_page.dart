import 'package:auto_route/auto_route.dart';
import 'package:example/web/router/router.gr.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  final routes = <PageRouteInfo>[
    BookListPageRoute(),
    SettingsPageRoute(),
  ];

  @override
  Widget build(_) => AutoParallelRouter(builder: (context, content) {
        final router = context.router;
        print('+++ Building ${router.currentRoute?.key}');
        var activeIndex = routes.indexWhere((r) => r.routeKey == router.currentRoute?.key);
        if (activeIndex == -1) activeIndex = 0;

        return Row(
          children: [
            NavigationRail(
              extended: false,
              selectedIndex: activeIndex,
              onDestinationSelected: (index) {
                print(router.stack.map((e) => e.key));
                // router.replace(routes[index]);
                if (router.stack.map((e) => e.data.key).contains(routes[index].routeKey)) {
                  router.setCurrentRoute(routes[index].routeKey);
                } else {
                  router.push(routes[index]);
                }
              },
              destinations: [
                // NavigationRailDestination(
                //   icon: Icon(Icons.account_tree_rounded),
                //   label: Text('Genres'),
                // ),
                NavigationRailDestination(
                  icon: Icon(Icons.source),
                  label: Text('Books'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
            Expanded(child: content)
          ],
        );
      });
}
