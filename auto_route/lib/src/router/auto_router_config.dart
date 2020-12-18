import 'package:auto_route/src/router/parser/route_information_parser.dart';
import 'package:flutter/widgets.dart';

import '../../auto_route.dart';
import '../matcher/route_matcher.dart';
import '../route/route_config.dart';
import 'auto_route_page.dart';
import 'controller/routing_controller.dart';

typedef PageBuilder = AutoRoutePage Function(RouteData data);
typedef PageFactory = Page<dynamic> Function(RouteData data);

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

  DefaultRouteParser defaultRouteParser({bool includePrefixMatches = true}) =>
      DefaultRouteParser(root.matcher, includePrefixMatches: includePrefixMatches);

  AutoRoutePage _pageBuilder(RouteData data) {
    var builder = pagesMap[data.config.page];
    assert(builder != null);
    return builder(data);
  }
}
