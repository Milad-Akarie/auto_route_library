import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'main_router.dart';

class TestPage extends StatelessWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.routeData.name),
        Text(context.routeData.match),
        Text(context.router.urlState.url),
      ],
    );
  }
}

@RoutePage()
class SecondHostPage extends StatelessWidget {
  const SecondHostPage({
    Key? key,
    this.useCustomLeading = false,
    this.hasDrawer = false,
  }) : super(key: key);
  final bool useCustomLeading;
  final bool hasDrawer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: useCustomLeading
              ? AutoLeadingButton(
                  builder: (context, leadingType, action) {
                    if (leadingType.isBack) {
                      return const BackButton();
                    } else if (leadingType.isClose) {
                      return const CloseButton();
                    } else if (leadingType.isDrawer) {
                      return IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () {},
                      );
                    } else if (leadingType.isNoLeading) {
                      return const SizedBox.shrink();
                    }
                    throw 'Invalid leading type';
                  },
                )
              : const AutoLeadingButton(),
        ),
        drawer: hasDrawer ? const Drawer() : null,
        body: const AutoRouter());
  }
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
class SecondNested3Page extends TestPage {
  const SecondNested3Page({Key? key}) : super(key: key);
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
class FourthPage extends TestPage {
  const FourthPage({Key? key}) : super(key: key);
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
  final String tabsType;

  const TabsHostPage({Key? key, @queryParam this.tabsType = 'IndexedStack'}) : super(key: key);

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

@RoutePage()
class DeclarativeRouterHostScreen extends StatelessWidget {
  const DeclarativeRouterHostScreen({Key? key, required this.pageNotifier}) : super(key: key);
  final ValueNotifier<int> pageNotifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: pageNotifier,
      builder: (context,value,_){
        return AutoRouter.declarative(
          routes: (_) => [
             const SecondNested1Route(),
             if(value >= 2)
               const SecondNested2Route(),
            if(value == 3)
              const SecondNested3Route()
          ],
        );
      },
    );
  }
}
