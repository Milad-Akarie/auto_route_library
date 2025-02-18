// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'main_router.dart';

/// generated route for
/// [DeclarativeRouterHostScreen]
class DeclarativeRouterHostRoute
    extends PageRouteInfo<DeclarativeRouterHostRouteArgs> {
  DeclarativeRouterHostRoute({
    Key? key,
    required ValueNotifier<int> pageNotifier,
    List<PageRouteInfo>? children,
  }) : super(
          DeclarativeRouterHostRoute.name,
          args: DeclarativeRouterHostRouteArgs(
            key: key,
            pageNotifier: pageNotifier,
          ),
          initialChildren: children,
        );

  static const String name = 'DeclarativeRouterHostRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DeclarativeRouterHostRouteArgs>();
      return DeclarativeRouterHostScreen(
        key: args.key,
        pageNotifier: args.pageNotifier,
      );
    },
  );
}

class DeclarativeRouterHostRouteArgs extends BaseRouteArgs {
  const DeclarativeRouterHostRouteArgs({
    required this.pageNotifier,
    super.key,
  });

  final ValueNotifier<int> pageNotifier;

  @override
  String toString() {
    return 'DeclarativeRouterHostRouteArgs{key: $key, pageNotifier: $pageNotifier}';
  }
}

/// generated route for
/// [FirstPage]
class FirstRoute extends PageRouteInfo<Null> {
  const FirstRoute({List<PageRouteInfo>? children})
      : super(
          FirstRoute.name,
          initialChildren: children,
        );

  static const String name = 'FirstRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const FirstPage();
    },
  );
}

/// generated route for
/// [FourthPage]
class FourthRoute extends PageRouteInfo<Null> {
  const FourthRoute({List<PageRouteInfo>? children})
      : super(
          FourthRoute.name,
          initialChildren: children,
        );

  static const String name = 'FourthRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const FourthPage();
    },
  );
}

/// generated route for
/// [NotFoundPage]
class NotFoundRoute extends PageRouteInfo<Null> {
  const NotFoundRoute({List<PageRouteInfo>? children})
      : super(
          NotFoundRoute.name,
          initialChildren: children,
        );

  static const String name = 'NotFoundRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const NotFoundPage();
    },
  );
}

/// generated route for
/// [SecondHostPage]
class SecondHostRoute extends PageRouteInfo<SecondHostRouteArgs> {
  SecondHostRoute({
    Key? key,
    bool useCustomLeading = false,
    bool hasDrawer = false,
    List<PageRouteInfo>? children,
  }) : super(
          SecondHostRoute.name,
          args: SecondHostRouteArgs(
            key: key,
            useCustomLeading: useCustomLeading,
            hasDrawer: hasDrawer,
          ),
          initialChildren: children,
        );

  static const String name = 'SecondHostRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SecondHostRouteArgs>(
          orElse: () => const SecondHostRouteArgs());
      return SecondHostPage(
        key: args.key,
        useCustomLeading: args.useCustomLeading,
        hasDrawer: args.hasDrawer,
      );
    },
  );
}

class SecondHostRouteArgs extends BaseRouteArgs {
  const SecondHostRouteArgs({
    this.useCustomLeading = false,
    this.hasDrawer = false,
    super.key,
  });

  final bool useCustomLeading;

  final bool hasDrawer;

  @override
  String toString() {
    return 'SecondHostRouteArgs{key: $key, useCustomLeading: $useCustomLeading, hasDrawer: $hasDrawer}';
  }
}

/// generated route for
/// [SecondNested1Page]
class SecondNested1Route extends PageRouteInfo<Null> {
  const SecondNested1Route({List<PageRouteInfo>? children})
      : super(
          SecondNested1Route.name,
          initialChildren: children,
        );

  static const String name = 'SecondNested1Route';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SecondNested1Page();
    },
  );
}

/// generated route for
/// [SecondNested2Page]
class SecondNested2Route extends PageRouteInfo<Null> {
  const SecondNested2Route({List<PageRouteInfo>? children})
      : super(
          SecondNested2Route.name,
          initialChildren: children,
        );

  static const String name = 'SecondNested2Route';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SecondNested2Page();
    },
  );
}

/// generated route for
/// [SecondNested3Page]
class SecondNested3Route extends PageRouteInfo<Null> {
  const SecondNested3Route({List<PageRouteInfo>? children})
      : super(
          SecondNested3Route.name,
          initialChildren: children,
        );

  static const String name = 'SecondNested3Route';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SecondNested3Page();
    },
  );
}

/// generated route for
/// [SecondPage]
class SecondRoute extends PageRouteInfo<Null> {
  const SecondRoute({List<PageRouteInfo>? children})
      : super(
          SecondRoute.name,
          initialChildren: children,
        );

  static const String name = 'SecondRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SecondPage();
    },
  );
}

/// generated route for
/// [Tab1Page]
class Tab1Route extends PageRouteInfo<Null> {
  const Tab1Route({List<PageRouteInfo>? children})
      : super(
          Tab1Route.name,
          initialChildren: children,
        );

  static const String name = 'Tab1Route';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const Tab1Page();
    },
  );
}

/// generated route for
/// [Tab2Nested1Page]
class Tab2Nested1Route extends PageRouteInfo<Null> {
  const Tab2Nested1Route({List<PageRouteInfo>? children})
      : super(
          Tab2Nested1Route.name,
          initialChildren: children,
        );

  static const String name = 'Tab2Nested1Route';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const Tab2Nested1Page();
    },
  );
}

/// generated route for
/// [Tab2Nested2Page]
class Tab2Nested2Route extends PageRouteInfo<Null> {
  const Tab2Nested2Route({List<PageRouteInfo>? children})
      : super(
          Tab2Nested2Route.name,
          initialChildren: children,
        );

  static const String name = 'Tab2Nested2Route';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const Tab2Nested2Page();
    },
  );
}

/// generated route for
/// [Tab2Page]
class Tab2Route extends PageRouteInfo<Null> {
  const Tab2Route({List<PageRouteInfo>? children})
      : super(
          Tab2Route.name,
          initialChildren: children,
        );

  static const String name = 'Tab2Route';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const Tab2Page();
    },
  );
}

/// generated route for
/// [Tab3Nested1Page]
class Tab3Nested1Route extends PageRouteInfo<Null> {
  const Tab3Nested1Route({List<PageRouteInfo>? children})
      : super(
          Tab3Nested1Route.name,
          initialChildren: children,
        );

  static const String name = 'Tab3Nested1Route';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const Tab3Nested1Page();
    },
  );
}

/// generated route for
/// [Tab3Nested2Page]
class Tab3Nested2Route extends PageRouteInfo<Null> {
  const Tab3Nested2Route({List<PageRouteInfo>? children})
      : super(
          Tab3Nested2Route.name,
          initialChildren: children,
        );

  static const String name = 'Tab3Nested2Route';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const Tab3Nested2Page();
    },
  );
}

/// generated route for
/// [Tab3Page]
class Tab3Route extends PageRouteInfo<Null> {
  const Tab3Route({List<PageRouteInfo>? children})
      : super(
          Tab3Route.name,
          initialChildren: children,
        );

  static const String name = 'Tab3Route';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const Tab3Page();
    },
  );
}

/// generated route for
/// [TabsHostPage]
class TabsHostRoute extends PageRouteInfo<TabsHostRouteArgs> {
  TabsHostRoute({
    Key? key,
    String tabsType = 'IndexedStack',
    bool useDefaultRoutes = false,
    List<PageRouteInfo>? children,
  }) : super(
          TabsHostRoute.name,
          args: TabsHostRouteArgs(
            key: key,
            tabsType: tabsType,
            useDefaultRoutes: useDefaultRoutes,
          ),
          rawQueryParams: {
            'tabsType': tabsType,
            'useDefaultRoutes': useDefaultRoutes,
          },
          initialChildren: children,
        );

  static const String name = 'TabsHostRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<TabsHostRouteArgs>(
          orElse: () => TabsHostRouteArgs(
                tabsType: queryParams.getString(
                  'tabsType',
                  'IndexedStack',
                ),
                useDefaultRoutes: queryParams.getBool(
                  'useDefaultRoutes',
                  false,
                ),
              ));
      return TabsHostPage(
        key: args.key,
        tabsType: args.tabsType,
        useDefaultRoutes: args.useDefaultRoutes,
      );
    },
  );
}

class TabsHostRouteArgs extends BaseRouteArgs {
  const TabsHostRouteArgs({
    this.tabsType = 'IndexedStack',
    this.useDefaultRoutes = false,
    super.key,
  });

  final String tabsType;

  final bool useDefaultRoutes;

  @override
  String toString() {
    return 'TabsHostRouteArgs{key: $key, tabsType: $tabsType, useDefaultRoutes: $useDefaultRoutes}';
  }
}

/// generated route for
/// [ThirdPage]
class ThirdRoute extends PageRouteInfo<Null> {
  const ThirdRoute({List<PageRouteInfo>? children})
      : super(
          ThirdRoute.name,
          initialChildren: children,
        );

  static const String name = 'ThirdRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ThirdPage();
    },
  );
}
