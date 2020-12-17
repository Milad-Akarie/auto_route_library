import 'package:auto_route/auto_route.dart';
import 'package:example/web/router/router.gr.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  @override
  Widget build(_) => AutoTabsRouter(
      routes: [BooksTabs(), SettingsTab()],
      builder: (context, content) => Row(
            children: [
              NavigationRail(
                extended: false,
                selectedIndex: context.tabsRouter.activeIndex,
                onDestinationSelected: (index) {
                  context.tabsRouter.setActiveIndex(index);
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
          ));
}
