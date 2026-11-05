import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

// Routes and pages the integration tests share. They mirror the generated
// routes of the package's headless tests (auto_route/test/main_router.dart),
// written by hand so these tests need no generated code.

/// Shows the route's name, so a test finds the page on screen by its name.
class TestPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Text(context.routeData.name)),
    );
  }
}

/// Each call a [RouteAwarePage] gets from its [AutoRouteObserver], as
/// `'<route name>.<call>'`, in order. Tests clear it before the steps they
/// check.
final routeAwareEvents = <String>[];

/// Shows the route's name like [TestPage], and records in [routeAwareEvents]
/// each [AutoRouteAware] call it gets.
class RouteAwarePage extends StatefulWidget {
  const new({super.key});

  @override
  State<RouteAwarePage> createState() => _RouteAwarePageState();
}

class _RouteAwarePageState extends State<RouteAwarePage>
    with AutoRouteAwareStateMixin<RouteAwarePage> {
  late final String _name = context.routeData.name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Text(context.routeData.name)),
    );
  }

  @override
  void didPush() => routeAwareEvents.add('$_name.didPush');

  @override
  void didPop() => routeAwareEvents.add('$_name.didPop');

  @override
  void didPushNext() => routeAwareEvents.add('$_name.didPushNext');

  @override
  void didPopNext() => routeAwareEvents.add('$_name.didPopNext');

  @override
  void didInitTabRoute(TabPageRoute? previousRoute) =>
      routeAwareEvents.add('$_name.didInitTabRoute');

  @override
  void didChangeTabRoute(TabPageRoute previousRoute) =>
      routeAwareEvents.add('$_name.didChangeTabRoute');
}

class FirstRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'FirstRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const TestPage());
}

class SecondRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'SecondRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const TestPage());
}

class ThirdRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'ThirdRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const TestPage());
}

class FourthRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'FourthRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const TestPage());
}

/// Hosts a nested stack router under an app bar with a back button.
class SecondHostRoute extends PageRouteInfo<void> {
  const new({List<PageRouteInfo>? children})
    : super(name, initialChildren: children);

  static const String name = 'SecondHostRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(
      appBar: AppBar(leading: const AutoLeadingButton()),
      body: const AutoRouter(),
    ),
  );
}

class SecondNested1Route extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'SecondNested1Route';
  static PageInfo page = PageInfo(name, builder: (_) => const TestPage());
}

class SecondNested3Route extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'SecondNested3Route';
  static PageInfo page = PageInfo(name, builder: (_) => const TestPage());
}

/// Hosts the tabs given by its route's children.
class TabsHostRoute extends PageRouteInfo<void> {
  const new({List<PageRouteInfo>? children})
    : super(name, initialChildren: children);

  static const String name = 'TabsHostRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const AutoTabsRouter());
}

class Tab1Route extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'Tab1Route';
  static PageInfo page = PageInfo(name, builder: (_) => const TestPage());
}

/// Hosts a nested stack router with no chrome around it.
class Tab2Route extends PageRouteInfo<void> {
  const new({List<PageRouteInfo>? children})
    : super(name, initialChildren: children);

  static const String name = 'Tab2Route';
  static PageInfo page = PageInfo(name, builder: (_) => const AutoRouter());
}

class Tab2Nested1Route extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'Tab2Nested1Route';
  static PageInfo page = PageInfo(name, builder: (_) => const TestPage());
}

class Tab2Nested2Route extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'Tab2Nested2Route';
  static PageInfo page = PageInfo(name, builder: (_) => const TestPage());
}

/// First to fourth pages at the root, as in
/// auto_route/test/simple_router/router.dart.
/// FourthRoute's guard always rejects.
RootStackRouter buildSimpleRouter() => .build(
  routes: [
    AutoRoute(page: FirstRoute.page, path: '/'),
    AutoRoute(page: SecondRoute.page),
    AutoRoute(page: ThirdRoute.page),
    AutoRoute(
      page: FourthRoute.page,
      guards: [AutoRouteGuard.simple((resolver, _) => resolver.reject())],
    ),
  ],
);
