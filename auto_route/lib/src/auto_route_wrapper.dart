import 'package:flutter/material.dart' show BuildContext, Widget;

// clients will implement this class to provide a wrapped route.
abstract class AutoRouteWrapper {
  Widget wrappedRoute(BuildContext context);
}
