import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/material.dart';

// class HomePage extends StatelessWidget {
//   @override
//   Widget build(_) => AutoTabsRouter(
//         routes: [BooksTab(), ProfileTab(), SettingsTab()],
//         duration: Duration(milliseconds: 400),
//         builder: (context, child, animation) {
//           var tabsRouter = context.tabsRouter;

//           return Scaffold(
//             appBar: AppBar(
//               title: Text(tabsRouter.current?.name ?? ''),
//             ),
//             body: FadeTransition(child: child, opacity: animation),
//             bottomNavigationBar: buildBottomNav(tabsRouter),
//           );
//         },
//       );

//   BottomNavigationBar buildBottomNav(TabsRouter tabsRouter) {
//     return BottomNavigationBar(
//       currentIndex: tabsRouter.activeIndex,
//       onTap: (index) {
//         tabsRouter.setActiveIndex(index);
//       },
//       items: [
//         BottomNavigationBarItem(
//           icon: Icon(Icons.source),
//           label: 'Books',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.person),
//           label: 'Profile',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.settings),
//           label: 'Settings',
//         ),
//       ],
//     );
//   }
// }

/// This example shows using a tabs router with a PageView
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController pageController;
  @override
  void initState() {
    pageController = PageController();
    super.initState();
  }

  @override
  Widget build(_) => AutoTabsRouter.pageView(
        routes: [BooksTab(), ProfileTab(), SettingsTab()],
        pageController: pageController,
        builder: (context, children, router) {
          var tabsRouter = context.tabsRouter;

          return Scaffold(
            appBar: AppBar(
              title: Text(tabsRouter.current?.name ?? ''),
            ),
            body: PageView(
              children: children,
              controller: pageController,
              onPageChanged: tabsRouter.setActiveIndex,
            ),
            // body: FadeTransition(child: child, opacity: animation),
            bottomNavigationBar: buildBottomNav(router),
          );
        },
      );

  BottomNavigationBar buildBottomNav(TabsRouter tabsRouter) {
    return BottomNavigationBar(
      currentIndex: tabsRouter.activeIndex,
      onTap: (index) {
        pageController
            .animateToPage(
              index,
              duration: Duration(milliseconds: 250),
              curve: Curves.linear,
            )
            .then((value) => tabsRouter.setActiveIndex(index));
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
