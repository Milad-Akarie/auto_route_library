import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(_) => AutoTabsRouter(
        routes: [BooksTab(), ProfileTab(), SettingsTab()],
        duration: Duration(milliseconds: 400),
        builder: (context, child, animation) {
          var tabsRouter = context.tabsRouter;
          return Scaffold(
            appBar: AppBar(
              title: Text(tabsRouter.currentRoute?.name),
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
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
