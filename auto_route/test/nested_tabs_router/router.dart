import 'package:auto_route/auto_route.dart';
import 'package:auto_route/empty_router_widgets.dart';
import 'package:flutter/material.dart';

import '../test_page.dart';
import 'router_test.dart';

part 'router.gr.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: [
    PageInfo(
      name: '/',
      page: TabsHostPage,
      children: tabRoutes,
    ),
    RedirectRoute(path: '*', redirectTo: '/'),
  ],
)
class AppRouter extends _$AppRouter {}

class TabsHostPage extends StatelessWidget {
  const TabsHostPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const routes = [
      Tab1Route(),
      Tab2Route(),
      Tab3Route(),
    ];

    if (tabsType == 'IndexedStack') {
      return const AutoTabsRouter(
        routes: routes,
      );
    }

    if (tabsType == 'PageView') {
      return const AutoTabsRouter.pageView(
        routes: routes,
      );
    }

    if (tabsType == 'TabBar') {
      return const AutoTabsRouter.tabBar(
        routes: routes,
      );
    }

    throw 'unsupported tabs type';
  }
}

const tabRoutes = [
  PageInfo(name: 'tab1', page: Tab1Page, initial: true),
  PageInfo(
    name: 'tab2',
    page: EmptyRouterPage,
    name: 'Tab2Route',
    children: [
      PageInfo(name: 'tab2Nested1', page: Tab2Nested1Page, initial: true),
      PageInfo(name: 'tab2Nested2', page: Tab2Nested2Page),
    ],
  ),
  PageInfo(
    name: 'tab3',
    name: 'Tab3Route',
    page: EmptyRouterPage,
    maintainState: false,
    children: [
      PageInfo(name: 'tab3Nested1', page: Tab3Nested1Page, initial: true),
      PageInfo(name: 'tab3Nested2', page: Tab3Nested2Page),
    ],
  ),
];

class Tab1Page extends TestPage {
  const Tab1Page({Key? key}) : super(key: key);
}

class Tab2Nested1Page extends TestPage {
  const Tab2Nested1Page({Key? key}) : super(key: key);
}

class Tab2Nested2Page extends TestPage {
  const Tab2Nested2Page({Key? key}) : super(key: key);
}

class Tab3Nested1Page extends TestPage {
  const Tab3Nested1Page({Key? key}) : super(key: key);
}

class Tab3Nested2Page extends TestPage {
  const Tab3Nested2Page({Key? key}) : super(key: key);
}
