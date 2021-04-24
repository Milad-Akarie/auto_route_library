import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(context) {
    return AutoTabsRouter(
        routes: const [
          BooksTab(),
          ProfileTab(),
          SettingsTab(),
        ],
        builder: (context, child, animation) {
          return Scaffold(
            appBar: AppBar(
              title: Text(context.tabsRouter.topRoute.name),
              leading: AutoBackButton(),
            ),
            body: FadeTransition(opacity: animation, child: child),
            bottomNavigationBar: buildBottomNav(context.tabsRouter),
          );
        });
  }

  BottomNavigationBar buildBottomNav(TabsRouter tabsRouter) {
    return BottomNavigationBar(
      currentIndex: tabsRouter.activeIndex,
      onTap: (index) => tabsRouter.setActiveIndex(index),
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
