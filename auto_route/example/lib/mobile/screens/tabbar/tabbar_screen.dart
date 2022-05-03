import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:example/mobile/screens/tabbar/page_one_Screen.dart';
import 'package:example/mobile/screens/tabbar/page_two_screen.dart';
import 'package:flutter/material.dart';

class TabbarScreen extends StatefulWidget {
  const TabbarScreen({Key? key}) : super(key: key);
  @override
  State<TabbarScreen> createState() => _TabbarScreenState();
}

class _TabbarScreenState extends State<TabbarScreen> {
  @override
  Widget build(BuildContext context) {
    return AutoTabBarScaffold(
      routes: [
        PageOneRoute(),
        PageTowRoute(),
      ],
      tabs: [
        Tab(
          text: 'Page one',
        ),
        Tab(
          text: 'Page two',
        ),
      ],
      tabsView: [
        PageOneScreen(),
        PageTwoScreen(),
      ],
      appBarTitle: Text('TabBar'),
    );
  }
}
