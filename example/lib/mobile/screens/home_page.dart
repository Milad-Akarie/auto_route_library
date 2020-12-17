import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(_) => AutoTabsRouter(
        routes: [BooksTab(), SettingsTab()],
        builder: (context, content) {
          var tabsRouter = context.tabsRouter;
          return Scaffold(
            appBar: AppBar(
              title: Text(tabsRouter.currentRoute?.key),
            ),
            body: content,
            bottomNavigationBar: BottomNavigationBar(
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
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          );
        },
      );
}
