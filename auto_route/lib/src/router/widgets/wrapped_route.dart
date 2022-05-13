import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@optionalTypeArgs
class WrappedRoute<T extends AutoRouteWrapper> extends StatelessWidget {
  const WrappedRoute({Key? key, required this.child}) : super(key: key);
  final T child;

  @override
  Widget build(BuildContext context) {
    return child.wrappedRoute(context);
  }
}
