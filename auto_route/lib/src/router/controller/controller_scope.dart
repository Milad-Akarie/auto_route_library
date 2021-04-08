import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@protected
class RoutingControllerScope extends InheritedWidget {
  final RoutingController controller;

  const RoutingControllerScope({
    required Widget child,
    required this.controller,
  }) : super(child: child);

  static RoutingController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RoutingControllerScope>()!.controller;
  }

  @override
  bool updateShouldNotify(covariant RoutingControllerScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

class StackRouterScope extends InheritedWidget {
  final StackRouter controller;

  const StackRouterScope({
    required Widget child,
    required this.controller,
  }) : super(child: child);

  static StackRouterScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StackRouterScope>();
  }

  @override
  bool updateShouldNotify(covariant StackRouterScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

class TabsRouterScope extends InheritedWidget {
  final TabsRouter controller;

  const TabsRouterScope({
    required Widget child,
    required this.controller,
  }) : super(child: child);

  static TabsRouterScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TabsRouterScope>();
  }

  @override
  bool updateShouldNotify(covariant TabsRouterScope oldWidget) {
    return controller != oldWidget.controller;
  }
}
