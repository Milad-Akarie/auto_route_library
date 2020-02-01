import 'dart:async';

import 'package:flutter/widgets.dart';

abstract class RouteGuard {
  Future<bool> canNavigate(
      BuildContext context, String routeName, Object arguments);
}
