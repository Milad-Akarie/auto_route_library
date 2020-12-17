import 'package:auto_route/src/router/parser/route_information_parser.dart';
import 'package:flutter/widgets.dart';

import '../../auto_route.dart';
import '../matcher/route_matcher.dart';
import '../route/route_data.dart';
import '../route/route_def.dart';
import 'auto_route_page.dart';
import 'controller/routing_controller.dart';

typedef PageBuilder = AutoRoutePage Function(RouteData data, RouteConfig def);
typedef PageFactory = Page<dynamic> Function(RouteData config);

abstract class AutoRouterConfig {
  RouteCollection routeCollection;
  StackRouter root;

  @mustCallSuper
  AutoRouterConfig() {
    assert(routes != null);
    routeCollection = RouteCollection.from(routes);
    root = TreeEntry(
      key: 'ROOT',
      routeCollection: routeCollection,
      pageBuilder: _pageBuilder,
    );
  }

  Map<Type, PageFactory> get pagesMap;

  List<RouteConfig> get routes;

  NativeRouteInfoParser get nativeRouteParser => NativeRouteInfoParser(routeCollection);

  WebRouteInfoParser get webRouteParser => WebRouteInfoParser(routeCollection);

  RouteInformationProvider defaultProvider(String initialPath) {
    return PlatformRouteInformationProvider(
      initialRouteInformation:
          RouteInformation(location: initialPath ?? '/' // WidgetsBinding.instance.window.defaultRouteName,
              ),
    );
  }

  AutoRoutePage _pageBuilder(RouteData data, RouteConfig def) {
    var builder = pagesMap[def.page];
    assert(builder != null);
    return builder(data);
  }
}