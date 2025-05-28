import 'package:auto_route_generator/src/builders/auto_route_builder.dart';
import 'package:auto_route_generator/src/builders/auto_router_builder.dart';
import 'package:build/build.dart';

/// Returns a [Builder] for router generation
Builder autoRouterBuilder(BuilderOptions options) {
  return AutoRouterBuilder(options: options);
}

/// Returns a [Builder] for route generation
Builder autoRouteBuilder(BuilderOptions options) {
  return AutoRouteBuilder(options: options);
}
