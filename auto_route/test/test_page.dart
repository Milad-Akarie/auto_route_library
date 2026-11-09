import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

import 'main_router.dart';

class _TestPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisSize: .min,
        children: [
          Text(context.routeData.name),
          Text(context.routeData.match),
          Text(context.router.urlState.url),
        ],
      ),
    );
  }
}

@RoutePage()
class SecondHostPage extends StatelessWidget {
  const new({
    super.key,
    this.shouldUseCustomLeading = false,
    this.hasDrawer = false,
  });

  final bool shouldUseCustomLeading;
  final bool hasDrawer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: shouldUseCustomLeading
            ? AutoLeadingButton(
                builder: (context, leadingType, action) {
                  if (leadingType.isBack) {
                    return const BackButton();
                  } else if (leadingType.isClose) {
                    return const CloseButton();
                  } else if (leadingType.isDrawer) {
                    return const IconButton(
                      icon: Icon(Icons.menu),
                      onPressed: null,
                    );
                  } else if (leadingType.isNoLeading) {
                    return const SizedBox.shrink();
                  }
                  throw StateError('Invalid leading type');
                },
              )
            : const AutoLeadingButton(),
      ),
      drawer: hasDrawer ? const Drawer() : null,
      body: const AutoRouter(),
    );
  }
}

@RoutePage()
class SecondNested1Page extends _TestPage {
  const new({super.key});
}

@RoutePage()
class SecondNested2Page extends _TestPage {
  const new({super.key});
}

@RoutePage()
class SecondNested3Page extends _TestPage {
  const new({super.key});
}

@RoutePage()
class NotFoundPage extends _TestPage {
  const new({super.key});
}

@RoutePage()
class FirstPage extends _TestPage {
  const new({super.key});
}

@RoutePage()
class SecondPage extends _TestPage {
  const new({super.key});
}

@RoutePage()
class ThirdPage extends _TestPage {
  const new({super.key});
}

@RoutePage()
class FourthPage extends _TestPage {
  const new({super.key});
}

@RoutePage()
class Tab1Page extends _TestPage {
  const new({super.key});
}

@RoutePage()
class Tab2Page extends AutoRouter {
  const new({super.key});
}

@RoutePage()
class Tab3Page extends AutoRouter {
  const new({super.key});
}

@RoutePage()
class Tab2Nested1Page extends _TestPage {
  const new({super.key});
}

@RoutePage()
class Tab2Nested2Page extends _TestPage {
  const new({super.key});
}

@RoutePage()
class Tab3Nested1Page extends _TestPage {
  const new({super.key});
}

@RoutePage()
class Tab3Nested2Page extends _TestPage {
  const new({super.key});
}

@RoutePage()
class TabsHostPage extends StatelessWidget {
  const new({
    super.key,
    @queryParam this.tabsType = 'IndexedStack',
    @queryParam this.shouldUseDefaultRoutes = false,
  });
  final String tabsType;
  final bool shouldUseDefaultRoutes;

  @override
  Widget build(BuildContext context) {
    final routes = shouldUseDefaultRoutes
        ? null
        : [const Tab1Route(), const Tab2Route(), const Tab3Route()];

    if (tabsType == 'IndexedStack') {
      return AutoTabsRouter(routes: routes);
    }

    if (tabsType == 'PageView') {
      return AutoTabsRouter.pageView(routes: routes);
    }

    if (tabsType == 'TabBar') {
      return AutoTabsRouter.tabBar(routes: routes);
    }

    throw StateError('unsupported tabs type');
  }
}

@RoutePage()
class DeclarativeRouterHostScreen extends StatelessWidget {
  const new({required this.pageNotifier, super.key});

  final ValueNotifier<int> pageNotifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: pageNotifier,
      builder: (context, value, _) {
        return AutoRouter.declarative(
          routes: (_) => [
            const SecondNested1Route(),
            if (value >= 2) const SecondNested2Route(),
            if (value == 3) const SecondNested3Route(),
          ],
        );
      },
    );
  }
}
