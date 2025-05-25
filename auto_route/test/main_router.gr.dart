// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'main_router.dart';

/// generated route for
/// [DeclarativeRouterHostScreen]
class DeclarativeRouterHostRoute extends PageRouteInfo<DeclarativeRouterHostRouteArgs> {
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

class DeclarativeRouterHostRouteArgs {
  const DeclarativeRouterHostRouteArgs({this.key, required this.pageNotifier});

  final Key? key;

  final ValueNotifier<int> pageNotifier;

  @override
  String toString() {
    return 'DeclarativeRouterHostRouteArgs{key: $key, pageNotifier: $pageNotifier}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DeclarativeRouterHostRouteArgs) return false;
    return key == other.key && pageNotifier == other.pageNotifier;
  }

  @override
  int get hashCode => key.hashCode ^ pageNotifier.hashCode;
}

/// generated route for
/// [FirstPage]
class FirstRoute extends PageRouteInfo<void> {
  const FirstRoute({List<PageRouteInfo>? children}) : super(FirstRoute.name, initialChildren: children);

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
class FourthRoute extends PageRouteInfo<void> {
  const FourthRoute({List<PageRouteInfo>? children}) : super(FourthRoute.name, initialChildren: children);

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
class NotFoundRoute extends PageRouteInfo<void> {
  const NotFoundRoute({List<PageRouteInfo>? children}) : super(NotFoundRoute.name, initialChildren: children);

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
        orElse: () => const SecondHostRouteArgs(),
      );
      return SecondHostPage(
        key: args.key,
        useCustomLeading: args.useCustomLeading,
        hasDrawer: args.hasDrawer,
      );
    },
  );
}

class SecondHostRouteArgs {
  const SecondHostRouteArgs({
    this.key,
    this.useCustomLeading = false,
    this.hasDrawer = false,
  });

  final Key? key;

  final bool useCustomLeading;

  final bool hasDrawer;

  @override
  String toString() {
    return 'SecondHostRouteArgs{key: $key, useCustomLeading: $useCustomLeading, hasDrawer: $hasDrawer}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SecondHostRouteArgs) return false;
    return key == other.key && useCustomLeading == other.useCustomLeading && hasDrawer == other.hasDrawer;
  }

  @override
  int get hashCode => key.hashCode ^ useCustomLeading.hashCode ^ hasDrawer.hashCode;
}

/// generated route for
/// [SecondNested1Page]
class SecondNested1Route extends PageRouteInfo<void> {
  const SecondNested1Route({List<PageRouteInfo>? children}) : super(SecondNested1Route.name, initialChildren: children);

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
class SecondNested2Route extends PageRouteInfo<void> {
  const SecondNested2Route({List<PageRouteInfo>? children}) : super(SecondNested2Route.name, initialChildren: children);

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
class SecondNested3Route extends PageRouteInfo<void> {
  const SecondNested3Route({List<PageRouteInfo>? children}) : super(SecondNested3Route.name, initialChildren: children);

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
class SecondRoute extends PageRouteInfo<void> {
  const SecondRoute({List<PageRouteInfo>? children}) : super(SecondRoute.name, initialChildren: children);

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
class Tab1Route extends PageRouteInfo<void> {
  const Tab1Route({List<PageRouteInfo>? children}) : super(Tab1Route.name, initialChildren: children);

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
class Tab2Nested1Route extends PageRouteInfo<void> {
  const Tab2Nested1Route({List<PageRouteInfo>? children}) : super(Tab2Nested1Route.name, initialChildren: children);

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
class Tab2Nested2Route extends PageRouteInfo<void> {
  const Tab2Nested2Route({List<PageRouteInfo>? children}) : super(Tab2Nested2Route.name, initialChildren: children);

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
class Tab2Route extends PageRouteInfo<void> {
  const Tab2Route({List<PageRouteInfo>? children}) : super(Tab2Route.name, initialChildren: children);

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
class Tab3Nested1Route extends PageRouteInfo<void> {
  const Tab3Nested1Route({List<PageRouteInfo>? children}) : super(Tab3Nested1Route.name, initialChildren: children);

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
class Tab3Nested2Route extends PageRouteInfo<void> {
  const Tab3Nested2Route({List<PageRouteInfo>? children}) : super(Tab3Nested2Route.name, initialChildren: children);

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
class Tab3Route extends PageRouteInfo<void> {
  const Tab3Route({List<PageRouteInfo>? children}) : super(Tab3Route.name, initialChildren: children);

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
          tabsType: queryParams.getString('tabsType', 'IndexedStack'),
          useDefaultRoutes: queryParams.getBool('useDefaultRoutes', false),
        ),
      );
      return TabsHostPage(
        key: args.key,
        tabsType: args.tabsType,
        useDefaultRoutes: args.useDefaultRoutes,
      );
    },
  );
}

class TabsHostRouteArgs {
  const TabsHostRouteArgs({
    this.key,
    this.tabsType = 'IndexedStack',
    this.useDefaultRoutes = false,
  });

  final Key? key;

  final String tabsType;

  final bool useDefaultRoutes;

  @override
  String toString() {
    return 'TabsHostRouteArgs{key: $key, tabsType: $tabsType, useDefaultRoutes: $useDefaultRoutes}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TabsHostRouteArgs) return false;
    return key == other.key && tabsType == other.tabsType && useDefaultRoutes == other.useDefaultRoutes;
  }

  @override
  int get hashCode => key.hashCode ^ tabsType.hashCode ^ useDefaultRoutes.hashCode;
}

/// generated route for
/// [ThirdPage]
class ThirdRoute extends PageRouteInfo<void> {
  const ThirdRoute({List<PageRouteInfo>? children}) : super(ThirdRoute.name, initialChildren: children);

  static const String name = 'ThirdRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ThirdPage();
    },
  );
}
