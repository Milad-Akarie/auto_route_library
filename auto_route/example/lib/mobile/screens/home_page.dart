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
  int activeIndex = 0;
  final GlobalKey<AutoTabsRouterState> _tabsRouterKey = GlobalKey();

  final _tabRoutes = [
    BooksTab(),
    ProfileTab(),
    SettingsTab(tab: 'default'),
  ];

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.topRoute.name),
        leading: AutoBackButton(),
      ),
      body: AutoTabsRouter(
        key: _tabsRouterKey,
        // activeIndex: activeIndex,
        // onNavigate: (route, initial) {
        //   var tabIndex = _tabRoutes.indexWhere((r) => r.routeName == route.routeName);
        //   if (tabIndex != -1) {
        //     activeIndex = tabIndex;
        //     if (!initial) setState(() {});
        //   }
        // },
        routes: List.unmodifiable(_tabRoutes),
      ),
      bottomNavigationBar: buildBottomNav(),
    );
  }

  BottomNavigationBar buildBottomNav() {
    final tabsController = _tabsRouterKey.currentState?.controller;
    return BottomNavigationBar(
      currentIndex: tabsController?.activeIndex ?? 0,
      onTap: (index) {
        tabsController?.setActiveIndex(index);
        // setState(() {
        //   activeIndex = index;
        // });
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
