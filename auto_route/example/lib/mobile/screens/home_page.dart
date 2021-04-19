import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/material.dart';

import 'user-data/data_collector.dart';

enum ConstEnum { value1 }

class HomePage extends StatelessWidget {
  final UserData userData;

  const HomePage({
    Key? key,
    ConstEnum enumValue = ConstEnum.value1,
    this.userData = const UserData(),
  }) : super(key: key);
  @override
  Widget build(context) {
    return AutoTabsScaffold(
      appBarBuilder: (context, router) {
        return AppBar(
          title: Text(router.current.name),
          leading: AutoBackButton(),
        );
      },
      routes: const [
        BooksTab(),
        ProfileTab(),
        SettingsTab(),
      ],
      bottomNavigationBuilder: (context, tabsRouter) {
        return buildBottomNav(tabsRouter);
      },
    );
  }

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

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.pushRoute(HomeRoute(
              children: [
                ProfileTab(children: [
                  ProfileRoute(),
                  MyBooksRoute(),
                ])
              ],
            ));
          },
          child: Text('Launch Home'),
        ),
      ),
    );
  }
}
