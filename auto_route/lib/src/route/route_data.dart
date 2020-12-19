import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/route/page_route_info.dart';
import 'package:flutter/widgets.dart';

// @immutable
// class RouteData {
//   final RouteData parent;
//   final PageRouteInfo route;
//   final String name;
//   final String path;
//   final String match;
//   final String fragment;
//   final Parameters queryParams;
//   final Parameters pathParams;
//
//   const RouteData({
//     @required this.path,
//     @required this.name,
//     @required this.queryParams,
//     @required this.pathParams,
//     @required this.route,
//     @required this.match,
//     this.fragment,
//     Object args,
//     this.parent,
//   });
//
//   List<RouteData> get breadcrumbs => List.unmodifiable([
//         if (parent != null) ...parent.breadcrumbs,
//         this,
//       ]);
//
//   factory RouteData.from(PageRouteInfo route, {RouteData parentData}) {
//     return RouteData(
//         route: route,
//         name: route.routeName,
//         path: route.path,
//         match: route.stringMatch,
//         pathParams: route.match?.pathParams,
//         queryParams: route.match?.queryParams,
//         parent: parentData,
//         fragment: route.match?.fragment);
//   }
//
//   static PageRouteInfo of(BuildContext context) {
//     var scope = context.dependOnInheritedWidgetOfExactType<RouteDataScope>();
//     assert(() {
//       if (scope == null) {
//         throw FlutterError('RouteData operation requested with a context that does not include an RouteData.\n'
//             'The context used to retrieve the RouteData must be that of a widget that '
//             'is a descendant of a AutoRoutePage.');
//       }
//       return true;
//     }());
//     return scope.data;
//   }
//
//   T getArgs<T extends RouteArgs>({T Function() orElse}) {
//     // if (pa == null) {
//     //   if (orElse == null) {
//     //     throw FlutterError('${T.toString()} can not be null because it has required parameters');
//     //   }
//     //   return orElse();
//     // }
//     // if (_args is! T) {
//     //   throw FlutterError('Expected [${T.toString()}],  found [${_args?.runtimeType}]');
//     // }
//     return route as T;
//   }
//
//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is RouteData &&
//           runtimeType == other.runtimeType &&
//           path == other.path &&
//           match == other.match &&
//           name == other.name &&
//           queryParams == other.queryParams &&
//           route == other.route;
//
//   @override
//   int get hashCode => path.hashCode ^ match.hashCode ^ name.hashCode ^ queryParams.hashCode ^ route.hashCode;
//
//   @override
//   String toString() {
//     return 'RouteData{match: $match, key: $name, queryParams: $queryParams}';
//   }
// }

class RouteDataScope extends InheritedWidget {
  final RouteData data;

  RouteDataScope({this.data, Widget child}) : super(child: child);

  @override
  bool updateShouldNotify(covariant RouteDataScope oldWidget) {
    return data != oldWidget.data;
  }
}
