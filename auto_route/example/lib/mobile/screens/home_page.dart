import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(context) {
    return Column(
      children: [
        Expanded(
          child: AutoTabsScaffold(
            homeIndex: 0,
            appBarBuilder: (context, tabsRouter) {
              return AppBar(
                  title: Text(context.topRoute.name),
                  leading: AutoBackButton());
            },
            routes: [
              BooksTab(),
              ProfileTab(),
              SettingsTab(tab: 'default'),
            ],
            bottomNavigationBuilder: buildBottomNav,
          ),
        ),
      ],
    );
  }

  BottomNavigationBar buildBottomNav(
      BuildContext context, TabsRouter tabsRouter) {
    return BottomNavigationBar(
      currentIndex: tabsRouter.activeIndex,
      onTap: tabsRouter.setActiveIndex,
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
