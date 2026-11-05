import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

// A router with a page of every route type, for the tests of what every page
// has, whatever its route type.

/// The name of each route [pageKindsRouter] holds, the home page first.
const pageKindNames = [
  'HomeRoute',
  'MaterialKindRoute',
  'CupertinoKindRoute',
  'AdaptiveKindRoute',
  'CustomKindRoute',
  'BuiltKindRoute',
];

/// Builds a router whose home page is at '/', with one page of every route
/// type above it. Each page shows its route name.
///
/// 'CustomKindRoute' slides in with [customTransitionsBuilder], over
/// [customDuration], with the iOS back swipe when [customCupertinoBackGesture]
/// is true. 'BuiltKindRoute' is built by a `customRouteBuilder`.
RootStackRouter pageKindsRouter({
  RouteTransitionsBuilder customTransitionsBuilder =
      TransitionsBuilders.slideLeft,
  Duration customDuration = const Duration(milliseconds: 300),
  bool customCupertinoBackGesture = false,
}) {
  return RootStackRouter.build(
    routes: [
      AutoRoute(path: '/', page: _page('HomeRoute')),
      MaterialRoute(path: '/material', page: _page('MaterialKindRoute')),
      CupertinoRoute(path: '/cupertino', page: _page('CupertinoKindRoute')),
      AdaptiveRoute(path: '/adaptive', page: _page('AdaptiveKindRoute')),
      CustomRoute(
        path: '/custom',
        page: _page('CustomKindRoute'),
        transitionsBuilder: customTransitionsBuilder,
        duration: customDuration,
        reverseDuration: customDuration,
        enableCupertinoBackGesture: customCupertinoBackGesture,
      ),
      CustomRoute(
        path: '/built',
        page: _page('BuiltKindRoute'),
        customRouteBuilder: <T>(context, child, page) => PageRouteBuilder<T>(
          settings: page,
          pageBuilder: (_, _, _) => child,
        ),
      ),
    ],
  );
}

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(
    appBar: AppBar(title: Text(name)),
    body: Center(child: Text('$name body')),
  ),
);
