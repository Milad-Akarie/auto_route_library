import 'package:auto_route/auto_route.dart';
import 'package:example/web/router/router.gr.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  final routes = <PageRouteInfo>[
    BooksTabs(),
    SettingsTab(),
  ];

  @override
  Widget build(_) => AutoTabsRouter(
      routes: routes,
      builder: (context, content) {
        final tabsRouter = AutoTabsRouter.of(context);
        print('+++ Building ${tabsRouter.currentRoute?.key}');
        var activeIndex = 0;
        if (tabsRouter.currentRoute?.key == SettingsTab.key) {
          activeIndex = 1;
        }

        return Row(
          children: [
            NavigationRail(
              extended: false,
              selectedIndex: activeIndex,
              onDestinationSelected: (index) {
                AutoTabsRouter.of(context).setActiveIndex(index);
              },
              destinations: [
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
