import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class SettingsTabPage extends StatelessWidget {
  @override
  Widget build(_) => AutoTabsRouter.indexedStack(
        duration: Duration(milliseconds: 400),
        builder: (context, child, animation) {
          var tabsRouter = context.tabsRouter;
          return Scaffold(
            appBar: AppBar(
              title: Text(tabsRouter.current?.name),
            ),
            body: FadeTransition(child: child, opacity: animation),
            bottomNavigationBar: buildBottomNav(tabsRouter),
          );
        },
      );

  BottomNavigationBar buildBottomNav(TabsRouter tabsRouter) {
    return BottomNavigationBar(
      currentIndex: tabsRouter.activeIndex,
      onTap: (index) {
        tabsRouter.setActiveIndex(index);
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.source),
          label: 'Books',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
