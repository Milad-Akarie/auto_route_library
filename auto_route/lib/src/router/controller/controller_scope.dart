import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@protected
class RoutingControllerScope extends InheritedWidget {
  final RoutingController controller;
  final NavigatorObserversBuilder navigatorObservers;
  final int stackHash;

  const RoutingControllerScope({
    required Widget child,
    required this.controller,
    required this.navigatorObservers,
    required this.stackHash,
  }) : super(child: child);

  static RoutingControllerScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RoutingControllerScope>();
  }

  @override
  bool updateShouldNotify(covariant RoutingControllerScope oldWidget) {
    return stackHash != oldWidget.stackHash;
  }
}

class StackRouterScope extends InheritedWidget {
  final StackRouter controller;
  final int stackHash;

  const StackRouterScope({
    required Widget child,
    required this.controller,
    required this.stackHash,
  }) : super(child: child);

  static StackRouterScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StackRouterScope>();
  }

  @override
  bool updateShouldNotify(covariant StackRouterScope oldWidget) {
    return stackHash != oldWidget.stackHash;
  }
}

class TabsRouterScope extends InheritedWidget {
  final TabsRouter controller;
  final int stackHash;
  const TabsRouterScope({
    required Widget child,
    required this.stackHash,
    required this.controller,
  }) : super(child: child);

  static TabsRouterScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TabsRouterScope>();
  }

  @override
  bool updateShouldNotify(covariant TabsRouterScope oldWidget) {
    return stackHash != oldWidget.stackHash;
  }
}
