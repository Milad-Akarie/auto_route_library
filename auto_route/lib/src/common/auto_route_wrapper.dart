import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' show BuildContext, Widget, StatelessWidget;
import 'package:meta/meta.dart' show optionalTypeArgs;

/// clients will implement this class to provide a wrapped route.
///
/// In some cases we want to wrap our screen with a parent widget usually to provide some values through context,
/// e.g wrapping your route with a custom Theme or a Provider, to do that simply implement AutoRouteWrapper,
/// and have wrappedRoute(context) method return (this) as the child of your wrapper widget
///
/// @RoutePage()
/// class ProductsScreen extends StatelessWidget implements AutoRouteWrapper {
///   @override
///   Widget wrappedRoute(BuildContext context) {
///   return Provider(create: (ctx) => ProductsBloc(), child: this);
///   }
abstract class AutoRouteWrapper {
  /// clients will implement this method to return their wrapped routes
  Widget wrappedRoute(BuildContext context);
}

/// A wrapper widget that's used by the [AutoRoutePage] to wrap widgets that implement
/// [AutoRouteWrapper]
@optionalTypeArgs
class WrappedRoute<T extends AutoRouteWrapper> extends StatelessWidget {
  /// default constructor
  const WrappedRoute({super.key, required this.child});

  /// The routeble-widget that implements [AutoRouteWrapper]
  final T child;

  @override
  Widget build(BuildContext context) {
    return child.wrappedRoute(context);
  }
}
