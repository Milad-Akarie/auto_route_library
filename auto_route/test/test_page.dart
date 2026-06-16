import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'main_router.dart';

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
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
  const SecondHostPage({
    super.key,
    this.useCustomLeading = false,
    this.hasDrawer = false,
  });

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
  const SecondNested1Page({super.key});
}

@RoutePage()
class SecondNested2Page extends TestPage {
  const SecondNested2Page({super.key});
}

@RoutePage()
class SecondNested3Page extends TestPage {
  const SecondNested3Page({super.key});
}

@RoutePage()
class NotFoundPage extends TestPage {
  const NotFoundPage({super.key});
}

@RoutePage()
class FirstPage extends TestPage {
  const FirstPage({super.key});
}

@RoutePage()
class SecondPage extends TestPage {
  const SecondPage({super.key});
}

@RoutePage()
class ThirdPage extends TestPage {
  const ThirdPage({super.key});
}

@RoutePage()
class FourthPage extends TestPage {
  const FourthPage({super.key});
}

@RoutePage()
class Tab1Page extends TestPage {
  const Tab1Page({super.key});
}

@RoutePage()
class Tab2Page extends AutoRouter {
  const Tab2Page({super.key});
}

@RoutePage()
class Tab3Page extends AutoRouter {
  const Tab3Page({super.key});
}

@RoutePage()
class Tab2Nested1Page extends TestPage {
  const Tab2Nested1Page({super.key});
}

@RoutePage()
class Tab2Nested2Page extends TestPage {
  const Tab2Nested2Page({super.key});
}

@RoutePage()
class Tab3Nested1Page extends TestPage {
  const Tab3Nested1Page({super.key});
}

@RoutePage()
class Tab3Nested2Page extends TestPage {
  const Tab3Nested2Page({super.key});
}

@RoutePage()
class TabsHostPage extends StatelessWidget {
  final String tabsType;
  final bool useDefaultRoutes;

  const TabsHostPage({
    super.key,
    @queryParam this.tabsType = 'IndexedStack',
    @queryParam this.useDefaultRoutes = false,
  });

  @override
  Widget build(BuildContext context) {
    final routes = useDefaultRoutes
        ? null
        : [
            const Tab1Route(),
            const Tab2Route(),
            const Tab3Route(),
          ];

    if (tabsType == 'IndexedStack') {
      return AutoTabsRouter(
        routes: routes,
      );
    }

    if (tabsType == 'PageView') {
      return AutoTabsRouter.pageView(
        routes: routes,
      );
    }

    if (tabsType == 'TabBar') {
      return AutoTabsRouter.tabBar(
        routes: routes,
      );
    }

    throw 'unsupported tabs type';
  }
}

@RoutePage()
class DeclarativeRouterHostScreen extends StatelessWidget {
  const DeclarativeRouterHostScreen({super.key, required this.pageNotifier});

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
            if (value == 3) const SecondNested3Route()
          ],
        );
      },
    );
  }
}

/// sample enum exercising the auto-detected enum converter code path
enum TestColor { red, green, blue }

@RoutePage()
class EnumPathPage extends TestPage {
  const EnumPathPage({super.key, @pathParam this.color = TestColor.red});

  final TestColor color;
}

@RoutePage()
class EnumQueryPage extends TestPage {
  const EnumQueryPage({super.key, @queryParam this.color});

  final TestColor? color;
}

/// custom value type used by [DatePage]
class TestDate {
  final int year;
  final int month;
  final int day;
  const TestDate(this.year, this.month, this.day);

  @override
  bool operator ==(Object other) => other is TestDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}

/// user-supplied [ParamConverter] used by [DatePage]
class TestDateConverter extends ParamConverter<TestDate> {
  const TestDateConverter();

  @override
  TestDate fromParam(String? value) {
    final parts = value!.split('-');
    return TestDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  @override
  String toParam(TestDate value) => '${value.year}-${value.month}-${value.day}';
}

const testDateConverter = TestDateConverter();

@RoutePage()
class DatePage extends TestPage {
  const DatePage({
    super.key,
    @QueryParam('date', testDateConverter) this.date,
  });

  final TestDate? date;
}
