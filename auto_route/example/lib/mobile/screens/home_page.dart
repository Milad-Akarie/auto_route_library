import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // setting the right index when an outer navigation happens
    // var tabsRouter = context.innerRouterOf<TabsRouter>(HomeRoute.name);
    // if (tabsRouter != null) {
    //   activeIndex = tabsRouter.activeIndex;
    // }
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.topRoute.name),
        leading: AutoBackButton(),
      ),
      body: AutoTabsRouter(
        activeIndex: activeIndex,
        routes: const [
          BooksTab(),
          ProfileTab(),
          SettingsTab(),
        ],
      ),
      bottomNavigationBar: buildBottomNav(),
    );
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
