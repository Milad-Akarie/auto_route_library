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

  final _tabRoutes = [
    BooksTab(),
    ProfileTab(),
    SettingsTab(tab: 'default'),
  ];

  @override
  Widget build(context) {
    print('Building home');
    return Scaffold(
        appBar: AppBar(
          title: Text(context.topRoute.name),
          leading: AutoBackButton(),
        ),
        body: AutoTabsRouter.declarative(
          activeIndex: activeIndex,
          onNavigate: (route, initial) async {
            var tabIndex = _tabRoutes.indexWhere((r) => r.routeName == route.routeName);
            if (tabIndex != -1) {
              activeIndex = tabIndex;
              // if (!initial) ;
              setState(() {});
            }
          },
          routes: List.unmodifiable(_tabRoutes),
        ),
        bottomNavigationBar: buildBottomNav());
  }

  BottomNavigationBar buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: activeIndex,
      onTap: (index) {
        setState(() {
          activeIndex = index;
        });
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
