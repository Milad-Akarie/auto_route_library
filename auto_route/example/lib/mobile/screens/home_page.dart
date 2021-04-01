import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(_) => AutoTabsRouter(
        // initialIndex: 1,
        routes: [
          BooksTab(),
          ProfileTab(),
          SettingsTab(),
        ],
        builder: (context, child, animation) {
          var tabsRouter = context.tabsRouter;
          return Scaffold(
            // appBar: PreferredSize(
            //   preferredSize: const Size.fromHeight(kToolbarHeight),
            //   child: NavigationChangeBuilder(
            //       scope: tabsRouter,
            //       // buildWhen: (router) => router == tabsRouter,
            //       builder: (context, router) {
            //         print('$router -> ${router.current?.name}');
            //         return AppBar(
            //           title: Text(router.current?.name ?? ''),
            //           leading: router.canPop
            //               ? IconButton(
            //                   icon: BackButtonIcon(),
            //                   onPressed: router.pop,
            //                 )
            //               : null,
            //         );
            //       }),
            // ),
            body: FadeTransition(opacity: animation, child: child),
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

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: ElevatedButton(
        onPressed: () {
          context.pushRoute(HomeRoute(children: [
            BooksTab(children: [BookDetailsRoute(id: 1)])
          ]));
        },
        child: Text('Launch Home'),
      ),
    );
  }
}
