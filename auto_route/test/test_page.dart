import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'main_router.dart';
import 'nested_tabs_router/router_test.dart';


class TestPage extends StatelessWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(context.routeData.name),
        Text(context.routeData.match),
        Text(context.router.urlState.url),
      ],
    );
  }
}


@RoutePage()
class SecondHostPage extends AutoRouter {
  const SecondHostPage({Key? key}) : super(key: key);
}
@RoutePage()
class SecondNested1Page extends TestPage {
  const SecondNested1Page({Key? key}) : super(key: key);
}

@RoutePage()
class SecondNested2Page extends TestPage {
  const SecondNested2Page({Key? key}) : super(key: key);
}

@RoutePage()
class NotFoundPage extends TestPage {
  const NotFoundPage({Key? key}) : super(key: key);
}

@RoutePage()
class FirstPage extends TestPage {
  const FirstPage({Key? key}) : super(key: key);
}
@RoutePage()
class SecondPage extends TestPage {
  const SecondPage({Key? key}) : super(key: key);
}
@RoutePage()
class ThirdPage extends TestPage {
  const ThirdPage({Key? key}) : super(key: key);
}

@RoutePage()
class Tab1Page extends TestPage {
  const Tab1Page({Key? key}) : super(key: key);
}

@RoutePage()
class Tab2Page extends AutoRouter {
  const Tab2Page({Key? key}) : super(key: key);
}

@RoutePage()
class Tab3Page extends AutoRouter {
  const Tab3Page({Key? key}) : super(key: key);
}

@RoutePage()
class Tab2Nested1Page extends TestPage {
  const Tab2Nested1Page({Key? key}) : super(key: key);
}

@RoutePage()
class Tab2Nested2Page extends TestPage {
  const Tab2Nested2Page({Key? key}) : super(key: key);
}

@RoutePage()
class Tab3Nested1Page extends TestPage {
  const Tab3Nested1Page({Key? key}) : super(key: key);
}

@RoutePage()
class Tab3Nested2Page extends TestPage {
  const Tab3Nested2Page({Key? key}) : super(key: key);
}

@RoutePage()
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
